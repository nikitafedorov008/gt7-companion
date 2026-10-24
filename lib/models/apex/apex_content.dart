// START_MODULE_CONTRACT
// PURPOSE: Represent the official Apex contents and ordered article blocks.
// SCOPE: JSON mapping and immutable reading data.
// DEPENDS: none
// LINKS: M-MODEL-APEX, V-M-MODEL-APEX
// END_MODULE_CONTRACT
// START_MODULE_MAP
// ApexChapter - one chapter containing named sections.
// ApexSection - one section containing article references.
// ApexArticleRef - title and API content path.
// ApexBlock - ordered heading, text, illustration, caption or callout.
// ApexArticle - a parsed official article.
// END_MODULE_MAP
class ApexChapter {
  const ApexChapter({required this.title, required this.sections});
  final String title;
  final List<ApexSection> sections;
  factory ApexChapter.fromJson(Map<String, dynamic> json) => ApexChapter(
    title: json['title'] as String,
    sections: (json['children'] as List<dynamic>)
        .map((item) => ApexSection.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class ApexSection {
  const ApexSection({required this.title, required this.articles});
  final String title;
  final List<ApexArticleRef> articles;
  factory ApexSection.fromJson(Map<String, dynamic> json) => ApexSection(
    title: json['title'] as String,
    articles: (json['grandChildren'] as List<dynamic>)
        .map((item) => ApexArticleRef.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class ApexArticleRef {
  const ApexArticleRef({required this.title, required this.path});
  final String title;
  final String path;
  static const introduction = ApexArticleRef(
    title: 'Beyond the Apex',
    path: '/top',
  );
  factory ApexArticleRef.fromJson(Map<String, dynamic> json) => ApexArticleRef(
    title: json['title'] as String,
    path: json['url'] as String,
  );
}

enum ApexBlockKind { heading, paragraph, image, caption, callout }

class ApexBlock {
  const ApexBlock({
    required this.kind,
    this.text = '',
    this.imageUrl,
    this.headingLevel = 2,
  });
  final ApexBlockKind kind;
  final String text;
  final Uri? imageUrl;
  final int headingLevel;
}

class ApexArticle {
  const ApexArticle({required this.reference, required this.blocks});
  final ApexArticleRef reference;
  final List<ApexBlock> blocks;
}
