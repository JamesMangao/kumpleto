import 'package:flutter/material.dart';

/// One curated home-screen category.
///
/// The feed tags documents with a long, precise vocabulary (81 slugs: `cfo`,
/// `denr`, `board-exam`, `civil-registry`…). That vocabulary is right for the
/// data, and wrong as a front door: a first-time reader looking for a birth
/// certificate should not have to know that it lives under `civil-registry`.
/// Each category here is a friendly name plus the tags that feed it, so the
/// chip can still filter the Documents list with real data.
class DocCategory {
  const DocCategory({
    required this.id,
    required this.en,
    required this.fil,
    required this.icon,
    required this.tags,
  });

  final String id;
  final String en;
  final String fil;
  final IconData icon;

  /// Every tag that belongs to this category; a document matches if it has at
  /// least one of them.
  final Set<String> tags;

  String label(String languageCode) => languageCode == 'fil' ? fil : en;
}

/// The eight-to-ten front doors Home shows. Order is deliberate: identity and
/// civil registry first (the documents people arrive for), niche ones last.
const docCategories = <DocCategory>[
  DocCategory(
    id: 'identity',
    en: 'IDs',
    fil: 'Pagkakakilanlan (ID)',
    icon: Icons.badge_outlined,
    tags: {'id', 'government-id', 'identification', 'umid', 'postal'},
  ),
  DocCategory(
    id: 'civil',
    en: 'Birth, Marriage, Death',
    fil: 'Kapanganakan, Kasal, Kamatayan',
    icon: Icons.article_outlined,
    tags: {'civil-registry', 'birth', 'marriage', 'death', 'correction', 'psa'},
  ),
  DocCategory(
    id: 'work',
    en: 'Work',
    fil: 'Trabaho',
    icon: Icons.work_outline,
    tags: {'job-hunt', 'employment', 'professional', 'skills', 'tesda'},
  ),
  DocCategory(
    id: 'driving',
    en: 'Driving',
    fil: 'Pagmamaneho',
    icon: Icons.directions_car_outlined,
    tags: {'driving', 'vehicle', 'transport', 'lto'},
  ),
  DocCategory(
    id: 'business',
    en: 'Business',
    fil: 'Negosyo',
    icon: Icons.storefront_outlined,
    tags: {
      'business',
      'permit',
      'registration',
      'livelihood',
      'freelancer',
      'sec',
      'corporation',
      'partnership',
      'zoning',
      'construction',
      'denr',
      'safety',
    },
  ),
  DocCategory(
    id: 'benefits',
    en: 'Benefits',
    fil: 'Benepisyo',
    icon: Icons.savings_outlined,
    tags: {'sss', 'health', 'housing', 'membership', 'pension', 'welfare'},
  ),
  DocCategory(
    id: 'senior',
    en: 'Senior / PWD / Solo Parent',
    fil: 'Senior / PWD / Solo Parent',
    icon: Icons.accessibility_new,
    tags: {'senior', 'elderly', 'disability', 'discounts', 'solo-parent'},
  ),
  DocCategory(
    id: 'travel',
    en: 'Travel',
    fil: 'Paglalakbay',
    icon: Icons.flight_takeoff,
    tags: {
      'travel',
      'passport',
      'overseas',
      'ofw',
      'visa',
      'migration',
      'seafarer',
      'authentication',
      'minors',
    },
  ),
  DocCategory(
    id: 'property',
    en: 'Land & property',
    fil: 'Lupa at bahay',
    icon: Icons.home_work_outlined,
    tags: {'property', 'land', 'title', 'lra'},
  ),
  DocCategory(
    id: 'tax',
    en: 'Taxes',
    fil: 'Buwis',
    icon: Icons.receipt_long_outlined,
    tags: {'tax', 'election'},
  ),
];

/// The documents readers most often come to look up one at a time, in the
/// order the requests arrive. Kept as ids so the label is whatever the feed
/// calls them in the reader's language.
const popularDocumentIcons = <String, IconData>{
  'nbi-clearance': Icons.verified_user_outlined,
  'psa-birth-certificate': Icons.article_outlined,
  'tin-bir': Icons.receipt_long_outlined,
  'sss': Icons.savings_outlined,
};

const popularDocumentIds = <String>[
  'nbi-clearance',
  'psa-birth-certificate',
  'tin-bir',
  'sss',
];
