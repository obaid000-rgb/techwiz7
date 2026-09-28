import 'package:fandom_verse/logic/resource_query.dart';
import 'package:fandom_verse/models/creator.dart';
import 'package:fandom_verse/models/fandom.dart';
import 'package:fandom_verse/models/post.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 9, 28, 12);

Post post(
  String id, {
  String title = 'Untitled',
  String content = '',
  String type = 'News',
  String category = 'gaming',
  String fandomId = '',
  String fandomName = '',
  String creatorId = '',
  String creatorName = '',
  List<String> tags = const [],
  int views = 0,
  int ageDays = 0,
  String status = 'active',
}) =>
    Post(
      id: id,
      title: title,
      content: content,
      category: category,
      contentType: type,
      fandomId: fandomId,
      fandomName: fandomName,
      creatorId: creatorId,
      creatorName: creatorName,
      tags: tags,
      viewCount: views,
      status: status,
      createdAt: now.subtract(Duration(days: ageDays)),
    );

List<String> ids(List<Post> posts) => [for (final p in posts) p.id];

void main() {
  final posts = [
    post('v1', title: 'Naruto final trailer', type: 'Video', category: 'anime',
        fandomId: 'naruto', fandomName: 'Naruto', creatorId: 'crunchy',
        creatorName: 'Crunchyroll', tags: ['trailer'], views: 50, ageDays: 1),
    post('n1', title: 'Free Fire patch notes', category: 'gaming',
        fandomId: 'free-fire', fandomName: 'Free Fire', creatorId: 'garena',
        creatorName: 'Garena', tags: ['patch-notes'], views: 5, ageDays: 2),
    post('g1', title: 'Cosplay gallery', type: 'Gallery', category: 'anime',
        fandomId: 'one-piece', fandomName: 'One Piece', creatorId: 'crunchy',
        creatorName: 'Crunchyroll', tags: ['cosplay'], views: 200, ageDays: 20),
    post('p1', title: 'Weekly anime talk', type: 'Podcast', category: 'anime',
        content: 'We talk Naruto and a new trailer', creatorId: 'pod',
        creatorName: 'Otaku Pod', tags: ['trailer'], views: 10, ageDays: 3),
    post('x1', title: 'Hidden draft', status: 'inactive', ageDays: 0),
  ];
  List<String> run(ResourceFilter f, [Set<String> interests = const {}]) =>
      ids(applyResourceFilter(posts, f, interests, now: now));

  group('filter groups alone', () {
    test('empty filter: all active posts, newest first', () {
      expect(run(const ResourceFilter()), ['v1', 'n1', 'p1', 'g1']);
      expect(const ResourceFilter().isEmpty, isTrue);
      expect(const ResourceFilter().activeCount, 0);
    });
    test('type', () {
      expect(run(const ResourceFilter(types: {'Video'})), ['v1']);
    });
    test('category', () {
      expect(run(const ResourceFilter(categoryIds: {'gaming'})), ['n1']);
    });
    test('fandom', () {
      expect(run(const ResourceFilter(fandomIds: {'one-piece'})), ['g1']);
    });
    test('creator', () {
      expect(run(const ResourceFilter(creatorIds: {'pod'})), ['p1']);
    });
  });

  group('combining', () {
    test('OR within a group', () {
      expect(run(const ResourceFilter(types: {'Video', 'Podcast'})), ['v1', 'p1']);
      expect(run(const ResourceFilter(creatorIds: {'crunchy', 'garena'})),
          ['v1', 'n1', 'g1']);
    });
    test('AND across groups', () {
      expect(
          run(const ResourceFilter(
              creatorIds: {'crunchy', 'garena'}, categoryIds: {'anime'})),
          ['v1', 'g1']);
      expect(
          run(const ResourceFilter(
              creatorIds: {'crunchy'}, categoryIds: {'anime'}, types: {'Gallery'})),
          ['g1']);
      expect(run(const ResourceFilter(types: {'Video'}, categoryIds: {'gaming'})),
          isEmpty);
    });
    test('activeCount and copyWith', () {
      const f = ResourceFilter(
          types: {'Video'}, creatorIds: {'a', 'b'}, sort: ResourceSort.trending);
      expect(f.activeCount, 4);
      final g = f.copyWith(myInterestsOnly: true);
      expect(g.activeCount, 5);
      expect(g.types, {'Video'});
      expect(g.copyWith(query: 'hi').activeCount, 5);
      expect(g.copyWith(query: 'hi').isEmpty, isFalse);
    });
  });

  group('keyword search', () {
    test('prefix match', () {
      expect(run(const ResourceFilter(query: 'nar')), ['v1', 'p1']);
      expect(run(const ResourceFilter(query: '  NAR  ')), ['v1', 'p1']);
      expect(run(const ResourceFilter(query: 'aruto')), isEmpty);
    });
    test('multi-word AND', () {
      expect(run(const ResourceFilter(query: 'naruto trailer')), ['v1', 'p1']);
      expect(run(const ResourceFilter(query: 'naruto patch')), isEmpty);
      expect(run(const ResourceFilter(query: 'free fire')), ['n1']);
    });
    test('ranking: title matches first, overrides chosen sort', () {
      // v1: title+fandom on "naruto" (3+2) and title on "trailer" (3) = 8
      // p1: body only on both words (1+1) = 2
      expect(
          run(const ResourceFilter(
              query: 'naruto trailer', sort: ResourceSort.mostViewed)),
          ['v1', 'p1']);
      final p = posts.firstWhere((x) => x.id == 'v1');
      expect(searchScore(p, queryWords('naruto trailer')), 8);
      expect(searchScore(p, queryWords('zzz')), isNull);
    });
    test('creator name and tags are searchable', () {
      expect(run(const ResourceFilter(query: 'otaku')), ['p1']);
      expect(run(const ResourceFilter(query: 'patch notes')), ['n1']);
    });
  });

  test('myInterestsOnly limits to the user interest categories', () {
    expect(run(const ResourceFilter(myInterestsOnly: true), {'gaming'}), ['n1']);
    expect(run(const ResourceFilter(myInterestsOnly: true)), isEmpty);
    expect(run(const ResourceFilter(myInterestsOnly: false), {'gaming'}).length, 4);
  });

  group('sorting and trending', () {
    test('most viewed', () {
      expect(run(const ResourceFilter(sort: ResourceSort.mostViewed)),
          ['g1', 'v1', 'p1', 'n1']);
    });
    test('trending weight: newer beats older with equal views', () {
      final newer = post('a', views: 30, ageDays: 1);
      final older = post('b', views: 30, ageDays: 8);
      expect(trendingWeight(newer, now), greaterThan(trendingWeight(older, now)));
      expect(trendingWeight(post('c'), now), closeTo(1.0, 1e-9));
      expect(trendingWeight(post('d', ageDays: 7), now), closeTo(0.5, 1e-9));
      expect(
          ids(applyResourceFilter([older, newer], const ResourceFilter(sort: ResourceSort.trending), {}, now: now)),
          ['a', 'b']);
    });
    test('trending sort differs from most viewed', () {
      // g1 has the most views but is 20 days old; v1 is 1 day old
      expect(run(const ResourceFilter(sort: ResourceSort.trending)).first, 'v1');
    });
  });

  test('matchFandoms by name or tag prefix', () {
    final fandoms = [
      Fandom(id: 'naruto', categoryId: 'anime', categoryName: 'Anime', name: 'Naruto',
          tags: const ['ninja'], createdAt: now),
      Fandom(id: 'ff', categoryId: 'g', categoryName: 'G', name: 'Free Fire',
          tags: const ['battle royale'], createdAt: now),
    ];
    expect(matchFandoms(fandoms, 'nar').map((f) => f.id), ['naruto']);
    expect(matchFandoms(fandoms, 'nin').map((f) => f.id), ['naruto']);
    expect(matchFandoms(fandoms, 'battle roy').map((f) => f.id), ['ff']);
    expect(matchFandoms(fandoms, 'naruto trailer').map((f) => f.id), ['naruto']);
    expect(matchFandoms(fandoms, 'free naruto').length, 2);
    expect(matchFandoms(fandoms, 'free fire naruto').map((f) => f.id), ['ff', 'naruto']);
    expect(matchFandoms(fandoms, 'zzz'), isEmpty);
    expect(matchFandoms(fandoms, ''), isEmpty);
  });

  test('matchCreators: name prefix, active only, best match first', () {
    Creator cr(String id, String name, {bool active = true}) =>
        Creator(id: id, name: name, isActive: active, createdAt: DateTime(2026));
    final creators = [
      cr('shezz', 'Shezz Reviews'),
      cr('otaku', 'Otaku Pod'),
      cr('gone', 'Shez Old', active: false),
    ];
    expect(matchCreators(creators, 'shez').map((c) => c.id), ['shezz']);
    expect(matchCreators(creators, 'SHEZZ reviews').first.id, 'shezz');
    expect(matchCreators(creators, 'pod').map((c) => c.id), ['otaku']);
    expect(matchCreators(creators, ''), isEmpty);
    expect(matchCreators(creators, 'zzz'), isEmpty);
  });
}
