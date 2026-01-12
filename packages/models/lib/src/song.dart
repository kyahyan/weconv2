import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'song.g.dart';

@JsonSerializable()
class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String content; // Lyrics/Chords
  final String key;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.content,
    required this.key,
  });

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
  Map<String, dynamic> toJson() => _$SongToJson(this);

  @override
  List<Object?> get props => [id, title, artist, content, key];
}
