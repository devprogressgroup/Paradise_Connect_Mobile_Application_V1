import 'dart:math';

import 'package:intl/intl.dart';
import 'package:progress_group/core/utils/helpers/app_time.dart';
import 'package:progress_group/features/auth/domain/entities/user_profile.dart';
import 'package:progress_group/features/marketing-feed/data/datasources/marketing_feed_remote_datasource.dart';
import 'package:progress_group/features/marketing-feed/data/models/feed_author_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/feed_comment_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/feed_post_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/personal_funnel_model.dart';
import 'package:progress_group/features/marketing-feed/data/models/wall_of_fame_model.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/feed_post_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/personal_funnel_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/save_feed_post_params.dart';

/// Data contoh Marketing Feed (diambil dari "Marketing Feed Prototype.html") selama endpoint
/// backend-nya belum ada. Semua perubahan — like, vote, komentar, kirim momen, post/poll baru,
/// draft, jadwal — cuma disimpan di memori dan hilang saat app ditutup. Post terjadwal otomatis
/// tayang begitu waktunya lewat (dicek tiap kali feed/draft dimuat).
///
/// Begitu API siap, ganti instance ini di `main.dart` dengan implementasi Dio dari
/// [MarketingFeedRemoteDataSource] — repository, cubit & UI tidak perlu diubah.
class MarketingFeedDummyDataSource implements MarketingFeedRemoteDataSource {
  MarketingFeedDummyDataSource() {
    _seed();
  }

  static const _latency = Duration(milliseconds: 300);
  static const _modId = 1;
  static const _meId = 2;

  final List<_DummyPost> _posts = [];
  int _nextId = 1;

  FeedAuthorModel _me = const FeedAuthorModel(id: _meId, name: 'Kamu', subtitle: 'Sales');

  static const Map<int, FeedAuthorModel> _authors = {
    _modId: FeedAuthorModel(id: _modId, name: 'Progress Group Marketing', subtitle: 'Moderator', isModerator: true),
    3: FeedAuthorModel(id: 3, name: 'Rina Kartika', subtitle: 'Sales · PAR1'),
    4: FeedAuthorModel(id: 4, name: 'Fajar Ramadhan', subtitle: 'SM · PRC'),
    5: FeedAuthorModel(id: 5, name: 'Agus Salim', subtitle: 'Sales · PAR2'),
    6: FeedAuthorModel(id: 6, name: 'Lina Nur', subtitle: 'Sales · PAR2'),
    7: FeedAuthorModel(id: 7, name: 'Tari Wulan', subtitle: 'Sales · PAR2'),
    8: FeedAuthorModel(id: 8, name: 'Dewi Kartika', subtitle: 'SM · PAR1'),
  };

  /// Pakai nama & jabatan user login sebagai penulis kiriman/komentar sendiri.
  void useProfile(UserProfileEntity profile) {
    _me = FeedAuthorModel(
      id: _meId,
      name: profile.fullName,
      subtitle: profile.positionName ?? profile.userRoleName,
      photoUrl: profile.photoUrl,
    );
  }

  FeedAuthorModel _author(int id) => id == _meId ? _me : _authors[id]!;

  DateTime get _now => AppTime.now();

  @override
  Future<FeedPageModel> getFeedPosts({int page = 1, int perPage = 10}) async {
    await Future.delayed(_latency);
    _publishDue();
    final mine = _posts
        .where((p) => p.authorId == _meId && (p.status == FeedPostStatus.review || p.status == FeedPostStatus.rejected))
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    final published = _posts.where((p) => p.status == FeedPostStatus.published).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    final all = [...mine, ...published];
    return FeedPageModel(
      items: all.skip((page - 1) * perPage).take(perPage).map(_toModel).toList(),
      currentPage: page,
      lastPage: max(1, (all.length / perPage).ceil()),
    );
  }

  @override
  Future<FeedPostModel> getFeedPost(int postId) async {
    await Future.delayed(_latency);
    _publishDue();
    return _toModel(_find(postId));
  }

  @override
  Future<List<WallOfFameLevelModel>> getWallOfFame() async {
    await Future.delayed(_latency);
    // [photoId] = foto contoh Unsplash, sama seperti foto post di _seed().
    WallOfFameEntryModel e(String name, String info, String highlight, [String? photoId]) => WallOfFameEntryModel(
          name: name,
          info: info,
          highlight: highlight,
          photoUrl: photoId == null
              ? null
              : 'https://images.unsplash.com/photo-$photoId?w=240&h=240&fit=crop&crop=faces&q=70',
        );
    return [
      WallOfFameLevelModel(
        level: 'TOP GM',
        champion: e('Hendra Wijaya', 'GM PAR1 & PAR2', 'Belum terkalahkan 3 bulan beruntun!', '1507003211169-0a1dd7228f2d'),
        runnersUp: [
          e('Ratna Puspita', 'PRC', 'Comeback kuat bulan ini 💪'),
          e('Agus Salim', 'PAR2', 'Konsisten terus di 3 besar'),
        ],
      ),
      WallOfFameLevelModel(
        level: 'TOP SM',
        champion: e('Dewi Kartika', 'SM PAR1', '14 SP tim dalam sebulan', '1494790108377-be9c29b29330'),
        runnersUp: [
          e('Fajar Ramadhan', 'PRC', 'Naik 4 peringkat'),
          e('Lina Nur', 'PAR2', 'Closing rate 38%'),
        ],
      ),
      WallOfFameLevelModel(
        level: 'TOP SPV',
        champion: e('Yoga Saputra', 'SPV PAR2', 'Tim paling cepat follow up', '1500648767791-00dcc994a43e'),
        runnersUp: [
          e('Mega Indah', 'PAR1', '9 SP tim'),
          e('Rudi Akbar', 'PRC', 'Visit terbanyak'),
        ],
      ),
      WallOfFameLevelModel(
        level: 'TOP SE',
        champion: e('Rina Kartika', 'SE PAR1', '8 unit SP bulan ini, #1 di PAR1', '1438761681033-6461ffad8d80'),
        runnersUp: [
          e('Budi Santoso', 'PAR1', '6 SP, appointment terbanyak'),
          e('Tari Wulan', 'PAR2', 'SP pertama bulan ini 🎉'),
        ],
      ),
    ];
  }

  @override
  Future<PersonalFunnelModel> getPersonalFunnel() async {
    await Future.delayed(_latency);
    return PersonalFunnelModel(
      periodLabel: DateFormat('MMMM yyyy', 'id_ID').format(_now),
      stages: const [
        FunnelStageEntity(label: 'Leads', count: 12),
        FunnelStageEntity(label: 'Appt', count: 8),
        FunnelStageEntity(label: 'Visit', count: 5),
        FunnelStageEntity(label: 'Reserve', count: 2),
        FunnelStageEntity(label: 'SP', count: 1),
      ],
    );
  }

  @override
  Future<FeedPostModel> reactToPost(int postId, FeedReaction reaction) async {
    await Future.delayed(_latency);
    final post = _find(postId);
    post.my = reaction;
    return _toModel(post);
  }

  @override
  Future<FeedPostModel> votePoll(int postId, List<int> optionIndexes) async {
    await Future.delayed(_latency);
    final poll = _find(postId).poll;
    if (poll == null) throw Exception('Post ini bukan poll');
    if (poll.myVotes.isNotEmpty) throw Exception('Kamu sudah menjawab poll ini');
    if (optionIndexes.isEmpty) throw Exception('Pilih jawaban dulu');
    for (final i in optionIndexes) {
      poll.votes[i]++;
    }
    poll.voters++;
    poll.myVotes = List.of(optionIndexes);
    return _toModel(_find(postId));
  }

  @override
  Future<List<FeedCommentModel>> getComments(int postId) async {
    await Future.delayed(_latency);
    return _find(postId).comments.map(_commentModel).toList();
  }

  @override
  Future<List<FeedCommentModel>> addComment(int postId, String text, {int? parentId}) async {
    await Future.delayed(_latency);
    final post = _find(postId);
    if (!post.settings.allowComment) throw Exception('Komentar dinonaktifkan untuk post ini');
    final comment = _DummyComment(_nextId++, _meId, text, _now);
    if (parentId == null) {
      post.comments.add(comment);
    } else {
      if (!post.settings.allowReply) throw Exception('Balasan komentar dinonaktifkan untuk post ini');
      post.comments.firstWhere((c) => c.id == parentId).replies.add(comment);
    }
    return post.comments.map(_commentModel).toList();
  }

  @override
  Future<List<FeedCommentModel>> toggleCommentLike(int postId, int commentId) async {
    await Future.delayed(_latency);
    final post = _find(postId);
    for (final c in [...post.comments, ...post.comments.expand((c) => c.replies)]) {
      if (c.id == commentId) c.liked = !c.liked;
    }
    return post.comments.map(_commentModel).toList();
  }

  @override
  Future<FeedPostModel> shareMoment(ShareFeedMomentParams params) async {
    await Future.delayed(_latency);
    final post = _DummyPost(
      id: _nextId++,
      authorId: _meId,
      status: FeedPostStatus.review,
      at: _now,
      text: params.text,
      media: List.of(params.media),
    );
    _posts.add(post);
    return _toModel(post);
  }

  @override
  Future<FeedPostModel> savePost(SaveFeedPostParams params) async {
    await Future.delayed(_latency);
    final scheduledAt = params.scheduledAt;
    if (!params.asDraft && scheduledAt != null && !scheduledAt.isAfter(_now)) {
      throw Exception('Pilih waktu tayang yang akan datang');
    }
    final status = params.asDraft
        ? FeedPostStatus.draft
        : scheduledAt != null
            ? FeedPostStatus.scheduled
            : FeedPostStatus.published;
    final at = status == FeedPostStatus.scheduled ? scheduledAt! : _now;

    final existing = params.postId == null ? null : _find(params.postId!);
    final oldPoll = existing?.poll;
    final poll = params.type == FeedPostType.poll
        ? _DummyPoll(
            options: List.of(params.pollOptions),
            // Suara lama dipertahankan selama jumlah opsinya tidak berubah.
            votes: oldPoll != null && oldPoll.options.length == params.pollOptions.length
                ? oldPoll.votes
                : List.filled(params.pollOptions.length, 0),
            voters: oldPoll?.voters ?? 0,
            multi: params.pollMultiple,
            image: params.pollImage,
            myVotes: oldPoll?.myVotes ?? const [],
          )
        : null;

    final post = existing ??
        _DummyPost(
          id: _nextId++,
          authorId: _modId,
          type: params.type,
          status: status,
          at: at,
          project: 'Semua',
          label: params.type == FeedPostType.poll ? 'Poll' : null,
        );
    post
      ..status = status
      ..at = at
      ..text = params.text
      ..media = List.of(params.media)
      ..poll = poll
      ..settings = params.settings;
    if (existing == null) _posts.add(post);
    return _toModel(post);
  }

  @override
  Future<List<FeedPostModel>> getDrafts() async {
    await Future.delayed(_latency);
    _publishDue();
    final list = _posts.where((p) => p.status == FeedPostStatus.scheduled || p.status == FeedPostStatus.draft).toList()
      ..sort((a, b) {
        if (a.status != b.status) return a.status == FeedPostStatus.scheduled ? -1 : 1;
        return a.at.compareTo(b.at);
      });
    return list.map(_toModel).toList();
  }

  @override
  Future<FeedPostModel> publishNow(int postId) async {
    await Future.delayed(_latency);
    final post = _find(postId)
      ..status = FeedPostStatus.published
      ..at = _now;
    return _toModel(post);
  }

  @override
  Future<void> deletePost(int postId) async {
    await Future.delayed(_latency);
    _posts.remove(_find(postId));
  }

  _DummyPost _find(int postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index < 0) throw Exception('Post tidak ditemukan');
    return _posts[index];
  }

  void _publishDue() {
    final now = _now;
    for (final p in _posts) {
      if (p.status == FeedPostStatus.scheduled && !p.at.isAfter(now)) {
        p.status = FeedPostStatus.published;
      }
    }
  }

  FeedCommentModel _commentModel(_DummyComment c) {
    return FeedCommentModel(
      id: c.id,
      author: _author(c.authorId),
      text: c.text,
      createdAt: c.at,
      likeCount: c.likes + (c.liked ? 1 : 0),
      isLiked: c.liked,
      replies: c.replies.map(_commentModel).toList(),
    );
  }

  // List selalu disalin supaya state lama di cubit tidak ikut berubah saat data dummy dimutasi.
  FeedPostModel _toModel(_DummyPost p) {
    final poll = p.poll;
    return FeedPostModel(
      id: p.id,
      type: p.type,
      status: p.status,
      author: _author(p.authorId),
      text: p.text,
      label: p.label,
      project: p.project,
      media: List.unmodifiable(p.media),
      poll: poll == null
          ? null
          : FeedPollModel(
              options: List.unmodifiable(poll.options),
              votes: List.unmodifiable(poll.votes),
              totalVoters: poll.voters,
              isMultiple: poll.multi,
              image: poll.image,
              myVotes: List.unmodifiable(poll.myVotes),
            ),
      link: p.link,
      settings: p.settings,
      publishAt: p.at,
      likeCount: p.likes + (p.my == FeedReaction.like ? 1 : 0),
      dislikeCount: p.dislikes + (p.my == FeedReaction.dislike ? 1 : 0),
      myReaction: p.my,
      commentCount: p.comments.fold(0, (n, c) => n + 1 + c.replies.length),
      latestComment: p.comments.isEmpty ? null : _commentModel(p.comments.last),
      isMine: p.authorId == _meId,
      fromAdminWeb: p.fromAdminWeb,
    );
  }

  void _seed() {
    final now = _now;
    final today = DateTime.utc(now.year, now.month, now.day);
    DateTime ago(Duration d) => now.subtract(d);
    _DummyComment c(int authorId, String text, Duration agoBy, [int likes = 0, List<_DummyComment>? replies]) =>
        _DummyComment(_nextId++, authorId, text, ago(agoBy), likes: likes, replies: replies);
    // Foto contoh gratis dari Unsplash (lisensi Unsplash, boleh dipakai tanpa atribusi). CDN-nya
    // mengirim header CORS, jadi tampil juga di build web/PWA. [label] = teks pengganti kalau foto
    // gagal dimuat (mis. offline).
    FeedMediaModel m(String photoId, String label, {int height = 800}) => FeedMediaModel(
          url: 'https://images.unsplash.com/photo-$photoId?w=800&h=$height&fit=crop&q=70',
          label: label,
        );
    const noDislike = FeedInteractionSettings(allowDislike: false);
    const linkOnly = FeedInteractionSettings(allowDislike: false, allowComment: false, allowReply: false);

    _posts.addAll([
      _DummyPost(
        id: _nextId++,
        authorId: _modId,
        project: 'PAR2',
        at: ago(const Duration(hours: 2)),
        likes: 128,
        dislikes: 3,
        fromAdminWeb: true,
        text: '**5 cara bikin sales kit kamu dilirik calon buyer di pameran** 🏬 — swipe buat lihat contoh boothnya, lengkap!',
        media: [
          m('1560518883-ce09059eeffa', 'Booth #1 · Taruh maket unit di meja paling depan'),
          m('1554224155-6726b3ff858f', 'Booth #2 · Brosur ringkas 1 halaman, siap dibawa'),
          m('1505373877841-8d25f7d46678', 'Booth #3 · Putar video walkthrough di layar'),
          m('1556740749-887f6717d7e4', 'Booth #4 · QR code langsung ke WhatsApp kamu'),
        ],
        comments: [
          c(3, 'Poin maket di depan itu ngefek banget, buyer jadi betah ngobrol 👍', const Duration(minutes: 90), 12, [
            c(_modId, 'Setuju! Template maket mini segera kami kirim ke tiap project ya.', const Duration(minutes: 80), 5),
          ]),
          c(4, 'Boleh minta file desain backdrop-nya?', const Duration(minutes: 70), 3, [
            c(_modId, 'Sudah ada di Sales Kit › Pameran 2026 🙌', const Duration(minutes: 60), 2),
            c(4, 'Siap, makasih!', const Duration(minutes: 55)),
          ]),
          c(5, 'QR code ke WA itu cerdas, leads langsung masuk tanpa ketik nomor.', const Duration(minutes: 20), 4),
        ],
      ),
      _DummyPost(
        id: _nextId++,
        authorId: _meId,
        project: 'PAR1',
        at: ago(const Duration(hours: 3)),
        likes: 40,
        dislikes: 2,
        text: 'Alhamdulillah, SP unit ke-6 bulan ini bareng Bu Sinta! Makasih tim yang bantu follow up.',
        media: [m('1521791136064-7986c2920216', 'SP · Unit ke-6 bulan ini!')],
        comments: [
          c(8, 'Mantap! Pertahankan 🔥', const Duration(hours: 2), 6),
          c(3, 'Selamat yaa 🎉', const Duration(minutes: 100), 2),
        ],
      ),
      _DummyPost(
        id: _nextId++,
        authorId: _modId,
        project: 'PAR1',
        label: 'Shoutout',
        at: ago(const Duration(hours: 20)),
        likes: 212,
        fromAdminWeb: true,
        text: '🏆 **Rina Kartika** cetak **8 unit SP** bulan ini — #1 di PAR1! Yuk kasih semangat 🎉',
        media: [m('1531545514256-b1400bc00f31', '8 UNIT SP · Rina Kartika · #1 di PAR1')],
        comments: [
          c(7, 'Inspiratif banget Bu Rina! 🔥', const Duration(hours: 18), 9, [
            c(3, 'Makasih Tari, kamu juga pasti bisa!', const Duration(hours: 17), 7),
          ]),
          c(6, 'Bagi tips follow up-nya dong kak 🙏', const Duration(hours: 15), 4),
        ],
      ),
      _DummyPost(
        id: _nextId++,
        authorId: _modId,
        type: FeedPostType.poll,
        project: 'PAR2',
        label: 'Poll',
        at: ago(const Duration(hours: 22)),
        fromAdminWeb: true,
        settings: noDislike,
        text: '**Fitur mana dari Cluster Aurora (PAR2) yang paling nge-jual ke buyer kamu?**',
        poll: _DummyPoll(
          options: ['Smart home system', 'Rooftop garden', 'Free carport 2 mobil'],
          votes: [38, 29, 17],
          voters: 84,
          image: m('1600585154340-be6161a56a0c', 'Cluster Aurora', height: 500),
        ),
        comments: [c(5, 'Rooftop garden paling sering ditanya keluarga muda.', const Duration(hours: 10), 3)],
      ),
      _DummyPost(
        id: _nextId++,
        authorId: _modId,
        project: 'PAR2',
        at: ago(const Duration(hours: 26)),
        likes: 96,
        dislikes: 1,
        fromAdminWeb: true,
        settings: const FeedInteractionSettings(allowReply: false),
        text: '**Cluster Aurora tipe 78/120 tinggal 4 unit!** Geser untuk lihat fasad, denah, skema promo, dan akses lokasi.',
        media: [
          m('1600596542815-ffad4c1539a9', 'Fasad · Tipe 78/120'),
          m('1503387762-592deb58ef4e', 'Denah unit'),
          m('1579621970563-ebec7560ff3e', 'Skema promo'),
          m('1524661135-423995f22d0b', 'Akses lokasi'),
        ],
        comments: [
          c(6, 'Unit hook masih ada kak?', const Duration(hours: 20), 1),
          c(4, 'Brosur PDF-nya sudah update harga terbaru belum?', const Duration(hours: 19), 2),
        ],
      ),
      _DummyPost(
        id: _nextId++,
        authorId: _modId,
        type: FeedPostType.poll,
        project: 'Semua',
        label: 'Poll',
        at: ago(const Duration(hours: 50)),
        fromAdminWeb: true,
        settings: noDislike,
        text: '**Objection handling apa yang paling sering kamu temui bulan ini?**',
        poll: _DummyPoll(
          options: ['Harga dianggap kemahalan', 'Lokasi jauh dari kota', 'Ragu soal legalitas/KPR'],
          votes: [92, 61, 47],
          voters: 156,
          multi: true,
        ),
      ),
      _DummyPost(
        id: _nextId++,
        authorId: _modId,
        type: FeedPostType.link,
        project: 'PAR2',
        at: ago(const Duration(hours: 52)),
        likes: 57,
        fromAdminWeb: true,
        settings: linkOnly,
        link: const FeedLinkModel(
          url: 'https://www.youtube.com',
          source: 'youtube',
          sourceLabel: 'YouTube · Progress Group Official',
          title: 'Walkthrough Cluster Aurora — Unit 78/120',
          description: 'Video tur lengkap unit contoh, cocok dikirim langsung ke WhatsApp calon buyer.',
        ),
        media: [m('1600607687939-ce8a6c25118c', 'Walkthrough Unit 78/120', height: 450)],
      ),
      _DummyPost(
        id: _nextId++,
        authorId: _modId,
        type: FeedPostType.link,
        project: 'Semua',
        at: ago(const Duration(hours: 74)),
        likes: 33,
        fromAdminWeb: true,
        settings: linkOnly,
        link: const FeedLinkModel(
          url: 'https://progressgroup.co.id',
          source: 'web',
          sourceLabel: 'Blog · progressgroup.co.id',
          title: '5 Tren Desain Rumah 2026 yang Wajib Kamu Tahu',
          description: 'Artikel edukasi produk — bahan obrolan sales presentation.',
        ),
        media: [m('1600210492486-724fe5c67fb0', 'Interior', height: 450)],
      ),
      _DummyPost(
        id: _nextId++,
        authorId: _modId,
        project: 'PAR2',
        label: 'Shoutout',
        at: ago(const Duration(hours: 76)),
        likes: 96,
        fromAdminWeb: true,
        settings: const FeedInteractionSettings(allowComment: false, allowReply: false),
        text: '🎉 Selamat **Tari Wulan** (PAR2) untuk SP pertamanya! Welcome to the club.',
        media: [m('1511632765486-a01980e01a18', 'SP PERTAMA · Tari Wulan')],
      ),
      _DummyPost(
        id: _nextId++,
        authorId: 4,
        project: 'PRC',
        at: ago(const Duration(hours: 98)),
        likes: 41,
        dislikes: 2,
        text: 'Open house PRC kemarin rame banget! 23 keluarga datang, 5 lanjut appointment minggu ini.',
        media: [
          m('1556761175-5973dc0f32e7', 'Open house PRC'),
          m('1484154218962-a197022b5858', 'Dapur unit contoh'),
        ],
        comments: [c(_modId, 'Keren tim PRC! Foto-fotonya boleh kami pakai untuk Instagram ya 🙌', const Duration(hours: 90), 8)],
      ),

      // Terjadwal — tayang otomatis begitu waktunya lewat.
      _DummyPost(
        id: _nextId++,
        authorId: _modId,
        status: FeedPostStatus.scheduled,
        project: 'PAR2',
        at: now.add(const Duration(minutes: 4)),
        fromAdminWeb: true,
        text: '**Promo akhir tahun Cluster Aurora:** DP 0% + free biaya KPR sampai 31 Desember 🏡',
        media: [
          m('1564013799919-ab600027ffc6', 'Promo akhir tahun'),
          m('1568605114967-8130f3a36994', 'Fasad sore · Tipe 78/120'),
        ],
      ),
      _DummyPost(
        id: _nextId++,
        authorId: _modId,
        status: FeedPostStatus.scheduled,
        project: 'Semua',
        at: today.add(const Duration(days: 1, hours: 8)),
        fromAdminWeb: true,
        text: '**Tips closing:** 3 pertanyaan pembuka saat site visit biar calon buyer cerita kebutuhannya.',
        media: [m('1570129477492-45c003edd2be', 'Tips closing')],
      ),
      _DummyPost(
        id: _nextId++,
        authorId: _modId,
        type: FeedPostType.poll,
        status: FeedPostStatus.scheduled,
        project: 'Semua',
        label: 'Poll',
        at: today.add(const Duration(days: 2, hours: 10)),
        fromAdminWeb: true,
        settings: noDislike,
        text: '**Jam berapa calon buyer paling responsif dibalas di WhatsApp?**',
        poll: _DummyPoll(options: ['Pagi 08–10', 'Siang 12–13', 'Malam 19–21'], votes: [0, 0, 0]),
      ),

      // Draft
      _DummyPost(
        id: _nextId++,
        authorId: _modId,
        status: FeedPostStatus.draft,
        project: 'Semua',
        at: ago(const Duration(hours: 1)),
        fromAdminWeb: true,
        text: 'Recap Pameran Mall Kota Kasablanka: 3 hari, 112 leads baru 🙌',
        media: [
          m('1540575467063-178a50c2df87', 'Booth pameran'),
          m('1511578314322-379afb476865', 'Suasana pameran'),
        ],
      ),
      _DummyPost(
        id: _nextId++,
        authorId: _modId,
        type: FeedPostType.link,
        status: FeedPostStatus.draft,
        project: 'PAR1',
        at: ago(const Duration(hours: 26)),
        fromAdminWeb: true,
        settings: linkOnly,
        link: const FeedLinkModel(
          url: 'https://www.youtube.com',
          source: 'youtube',
          sourceLabel: 'YouTube · Progress Group Official',
          title: 'Testimoni penghuni PAR1: kenapa pilih Paradise?',
          description: 'Cerita 3 keluarga yang sudah serah terima kunci.',
        ),
        media: [m('1586023492125-27b2c045efd7', 'Testimoni penghuni PAR1', height: 450)],
      ),
    ]);
  }
}

class _DummyPost {
  final int id;
  final int authorId;
  final FeedPostType type;
  FeedPostStatus status;
  DateTime at;
  String text;
  final String? label;
  final String? project;
  List<FeedMediaEntity> media;
  _DummyPoll? poll;
  final FeedLinkModel? link;
  FeedInteractionSettings settings;

  /// Reaksi orang lain — reaksi user sendiri ada di [my].
  final int likes;
  final int dislikes;
  FeedReaction my = FeedReaction.none;
  final List<_DummyComment> comments;
  final bool fromAdminWeb;

  _DummyPost({
    required this.id,
    required this.authorId,
    this.type = FeedPostType.post,
    this.status = FeedPostStatus.published,
    required this.at,
    this.text = '',
    this.label,
    this.project,
    this.media = const [],
    this.poll,
    this.link,
    this.settings = const FeedInteractionSettings(),
    this.likes = 0,
    this.dislikes = 0,
    List<_DummyComment>? comments,
    this.fromAdminWeb = false,
  }) : comments = comments ?? [];
}

class _DummyPoll {
  final List<String> options;
  final List<int> votes;
  int voters;
  final bool multi;
  final FeedMediaEntity? image;
  List<int> myVotes;

  _DummyPoll({
    required this.options,
    required List<int> votes,
    this.voters = 0,
    this.multi = false,
    this.image,
    List<int> myVotes = const [],
  })  : votes = List.of(votes),
        myVotes = List.of(myVotes);
}

class _DummyComment {
  final int id;
  final int authorId;
  final String text;
  final DateTime at;

  /// Like dari orang lain — like user sendiri ada di [liked].
  final int likes;
  bool liked = false;
  final List<_DummyComment> replies;

  _DummyComment(this.id, this.authorId, this.text, this.at, {this.likes = 0, List<_DummyComment>? replies})
      : replies = replies ?? [];
}
