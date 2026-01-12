import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:models/models.dart';

class OrganizationRepository {
  final SupabaseClient _client;

  OrganizationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<List<Organization>> getOrganizations() async {
    final response = await _client.from('organizations').select();
    return (response as List).map((e) => Organization.fromJson(e)).toList();
  }

  Future<List<Organization>> getPendingOrganizations() async {
    final response = await _client
        .from('organizations')
        .select()
        .eq('status', 'pending');
    return (response as List).map((e) => Organization.fromJson(e)).toList();
  }

  Future<void> updateOrganizationStatus(String orgId, String status) async {
    await _client
        .from('organizations')
        .update({'status': status})
        .eq('id', orgId);
  }

  Future<void> rejectAndDeletionOrganization(String orgId) async {
    await _client.rpc('reject_and_delete_organization', params: {
      'target_org_id': orgId,
    });
  }

  Future<void> createOrganizationWithBranch({
    required String orgName, 
    required String branchName
  }) async {
    final userId = _client.auth.currentUser!.id;

    // 1. Create Organization (Default status is pending via DB default)
    final orgResponse = await _client.from('organizations').insert({
      'name': orgName,
      'owner_id': userId,
      'status': 'pending', 
    }).select().single();
    
    final org = Organization.fromJson(orgResponse);

    // 2. Create Default Branch
    final branchResponse = await _client.from('branches').insert({
      'organization_id': org.id,
      'name': branchName,
    }).select().single();
    
    final branch = Branch.fromJson(branchResponse);

    // 3. Add Owner as Member
    await _client.from('organization_members').insert({
      'user_id': userId,
      'organization_id': org.id,
      'branch_id': branch.id,
      'role': 'owner',
    });
  }

  Future<Organization?> getUserOrganization() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('organization_members')
        .select('organization:organizations(*)')
        .eq('user_id', userId)
        .limit(1) // In case of specific branches, just take one to identify the org
        .maybeSingle();

    if (response == null || response['organization'] == null) {
      return null;
    }

    return Organization.fromJson(response['organization']);
  }

  // Branch Management
  Future<List<Branch>> getBranches(String orgId) async {
    final response = await _client
        .from('branches')
        .select()
        .eq('organization_id', orgId);
    return (response as List).map((e) => Branch.fromJson(e)).toList();
  }

  Future<void> createBranch(String orgId, String branchName) async {
    await _client.from('branches').insert({
      'organization_id': orgId,
      'name': branchName,
    });
  }

  Future<List<Organization>> getApprovedOrganizations() async {
    final response = await _client
        .from('organizations')
        .select()
        .eq('status', 'approved')
        .order('name', ascending: true);
    return (response as List).map((e) => Organization.fromJson(e)).toList();
  }

  // Join Methods
  Future<void> joinOrganization(String orgId) async {
    final userId = _client.auth.currentUser!.id;
    
    // 1. Find Default Branch (first created) to "fall to"
    // We assume every org has at least one branch created at start
    final branchRes = await _client
        .from('branches')
        .select()
        .eq('organization_id', orgId)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();
        
    final String? defaultBranchId = branchRes?['id'];

    // 2. Join (Upsert to handle re-joining/switching)
    await _client.from('organization_members').upsert({
      'user_id': userId,
      'organization_id': orgId,
      'branch_id': defaultBranchId, // Can be null if really no branches exist
      'role': 'member',
    }, onConflict: 'user_id, organization_id, branch_id');
  }

  Future<void> joinBranch(String orgId, String branchId) async {
    final userId = _client.auth.currentUser!.id;
    // Update existing member record or insert new one
    // Using upsert with the primary/unique key constraint on (user_id, organization_id)
    await _client.from('organization_members').upsert({
      'user_id': userId,
      'organization_id': orgId,
      'branch_id': branchId,
      'role': 'member',
    }, onConflict: 'user_id, organization_id, branch_id');
  }

  Future<void> leaveBranch(String orgId, String branchId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    
    await _client.from('organization_members').delete().match({
      'user_id': userId,
      'organization_id': orgId,
      'branch_id': branchId,
    });
  }

  Future<List<String>> getJoinedBranchIds(String orgId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    
    final response = await _client
        .from('organization_members')
        .select('branch_id')
        .eq('user_id', userId)
        .eq('organization_id', orgId);
        
    return (response as List).map((e) => e['branch_id'] as String).toList();
  }

  Future<Map<String, String>> getUserBranchRoles(String orgId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final response = await _client
        .from('organization_members')
        .select('branch_id, role')
        .eq('user_id', userId)
        .eq('organization_id', orgId);

    final Map<String, String> roles = {};
    for (var item in response as List) {
      if (item['branch_id'] != null) {
        roles[item['branch_id'] as String] = item['role'] as String;
      }
    }
    return roles;
  }

  Future<List<Map<String, dynamic>>> getBranchMembers(String orgId, String branchId) async {
    final response = await _client
        .from('organization_members')
        .select('id, user_id, role, ministry_roles, profile:profiles(username, avatar_url)')
        .eq('organization_id', orgId)
        .eq('branch_id', branchId);
        
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateMemberRole(String membershipId, String newRole) async {
    await _client.from('organization_members').update({
      'role': newRole,
    }).eq('id', membershipId);
  }

  Future<void> updateMinistryRoles(String membershipId, List<String> roles) async {
    await _client.from('organization_members').update({
      'ministry_roles': roles,
    }).eq('id', membershipId);
  }

  Future<bool> isOrgAdmin() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('organization_members')
        .select('role')
        .eq('user_id', userId)
        .or('role.eq.owner,role.eq.admin'); 
    
    return (response as List).isNotEmpty;
  }
}
