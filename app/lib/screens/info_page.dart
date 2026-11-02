import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/shared.dart';

/// Which static page to render.
enum InfoKind { about, disclaimer, privacy }

/// One titled block of prose on an [InfoPage].
class InfoSection {
  const InfoSection(this.heading, this.body);

  final String heading;
  final String body;
}

/// A scrollable in-app page whose content ships inside the APK.
///
/// These used to open GitHub in a browser. Everything is now rendered by the
/// app itself, in the language the user picked, and nothing leaves the device.
class InfoPage extends StatelessWidget {
  const InfoPage({super.key, required this.kind});

  final InfoKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isFilipino = Localizations.localeOf(context).languageCode == 'fil';
    final sections = InfoContent.sections(kind, filipino: isFilipino);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          switch (kind) {
            InfoKind.about => l10n.settingsAbout,
            InfoKind.disclaimer => l10n.settingsDisclaimer,
            InfoKind.privacy => l10n.settingsPrivacy,
          },
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            const Center(child: KumpletoLogo(size: 84, radius: 22)),
            const SizedBox(height: 16),
            Center(
              child: Text(
                l10n.appTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF23352C)
                      : const Color(0xFFE2EFE9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.unofficialBadge,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            for (final section in sections) ...[
              Text(
                section.heading,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                section.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// Static bilingual copy for the in-app pages.
abstract final class InfoContent {
  static List<InfoSection> sections(InfoKind kind, {required bool filipino}) {
    final text = filipino ? _fil : _en;
    return switch (kind) {
      InfoKind.about => text.about,
      InfoKind.disclaimer => text.disclaimer,
      InfoKind.privacy => text.privacy,
    };
  }

  static const _Content _en = _Content(
    about: [
      InfoSection(
        'What Kumpleto is',
        'An offline checklist of what Philippine government documents ask for: '
            'the requirements, the steps, the fee, the processing time and the '
            'official source for each one. Tick a requirement and Kumpleto '
            'remembers it on this phone.',
      ),
      InfoSection(
        'Not a government app',
        'Kumpleto is unofficial. It is not affiliated with, endorsed by, or '
            'connected to any Philippine government agency, and it does not '
            'speak for any of them. Always confirm with the agency or your '
            'barangay hall before you travel, pay, or file.',
      ),
      InfoSection(
        'Offline first',
        'The document data ships inside the app, so every checklist, step and '
            'fee works with no signal. The only network request is the optional '
            '"Check for updates" in Settings, which you can ignore entirely.',
      ),
      InfoSection(
        'Where the data comes from',
        'Every entry cites an official source URL. An entry only loses the '
            '"Unverified" badge after a maintainer has read that source and '
            'recorded who verified it and when. Entries that are still '
            'unverified say so on their own screen.',
      ),
      InfoSection(
        'Barangay and LGU documents',
        'Barangays and local governments set their own clearances, fees and '
            'validity. Entries for those documents list the usual national '
            'requirements and tell you to confirm the rest at your own hall.',
      ),
      InfoSection(
        'Place names',
        'Region, province, city, municipality and barangay names come from the '
            'Philippine Standard Geographic Code (PSGC) published by the '
            'Philippine Statistics Authority, used under CC BY 4.0 and stored '
            'in the app without modification. Postal codes follow PHLPost and '
            'are set per city or municipality, not per barangay.',
      ),
      InfoSection(
        'Licences',
        'The app and its document data are open source. Library licences are '
            'listed under Open-source licenses in Settings.',
      ),
    ],
    disclaimer: [
      InfoSection(
        'Unofficial. Not a government app.',
        'Kumpleto is a community project. It is not a government app, it is '
            'not connected to any agency, and nothing in it is legal advice.',
      ),
      InfoSection(
        'Requirements change',
        'Fees, requirements and processing times are changed by agencies and '
            'by local ordinances without notice. An entry can be out of date '
            'even if it was correct when it was written.',
      ),
      InfoSection(
        'What "Unverified" means',
        'Most entries are still drafts. The badge means no maintainer has read '
            'an official source for that entry yet. Treat every number and '
            'every list on an unverified entry as a starting point only.',
      ),
      InfoSection(
        'Check before you spend',
        'Confirm with the agency, or with your barangay hall, before you pay a '
            'fee, book a trip, or file an application. You are responsible for '
            'the decisions you make with this information.',
      ),
      InfoSection(
        'No warranty',
        'The data is provided as is, without warranty of any kind. The '
            'maintainers are not liable for losses caused by using it.',
      ),
    ],
    privacy: [
      InfoSection(
        'No account, no sign-in',
        'Kumpleto has no login, no profile and no server that knows who you '
            'are. There is nothing to register and nothing to link.',
      ),
      InfoSection(
        'Your checklist stays on your phone',
        'Every tick you make is written to a local database inside the app. It '
            'is never uploaded, synced, or shared with anyone. Your chosen '
            'language, theme and location are stored the same way.',
      ),
      InfoSection(
        'No tracking',
        'There is no analytics, no advertising, no crash reporting and no '
            'third-party tracking SDK in the app.',
      ),
      InfoSection(
        'When the app uses the network',
        'Only two things can touch the internet, and both are started by you: '
            'the optional "Check for updates" in Settings, and a link you tap '
            'yourself (for example a document\'s official source). The update '
            'check sends nothing about you and is skipped if you never tap it.',
      ),
      InfoSection(
        'Removing your data',
        'Reset all progress in Settings clears every tick immediately. '
            'Uninstalling the app removes the local database with it, so your '
            'progress goes away for good.',
      ),
    ],
  );

  static const _Content _fil = _Content(
    about: [
      InfoSection(
        'Ano ang Kumpleto',
        'Isang offline na checklist ng mga kailangan sa dokumento ng gobyerno: '
            'ang mga requirement, hakbang, bayad, tagal ng proseso at ang '
            'opisyal na pinagmulan ng bawat isa. Mag-tsek ka ng requirement at '
            'tatandaan ito ng Kumpleto sa teleponong ito.',
      ),
      InfoSection(
        'Hindi ito app ng gobyerno',
        'Unofficial ang Kumpleto. Wala itong kaugnayan, pagsang-ayon, o '
            'koneksyon sa kahit anong ahensya ng gobyerno, at hindi ito '
            'nagsasalita para sa kanila. Laging kumpirmahin sa ahensya o sa '
            'barangay hall bago maglakbay, magbayad, o mag-file.',
      ),
      InfoSection(
        'Offline una',
        'Nasa loob ng app ang datos ng mga dokumento, kaya gumagana ang bawat '
            'checklist, hakbang at bayad kahit walang signal. Ang tanging '
            'network request ay ang opsyonal na "Check for updates" sa '
            'Settings, na pwedeng hindi gamitin.',
      ),
      InfoSection(
        'Saan galing ang datos',
        'Bawat entry ay may opisyal na source URL. Nawawala lang ang '
            '"Unverified" na badge kapag may nagbasa na ng source at naitala '
            'kung sino at kailan ito ni-verify. Ang mga hindi pa verified ay '
            'sinasabi ito sa sariling screen.',
      ),
      InfoSection(
        'Dokumento ng barangay at LGU',
        'Ang barangay at lokal na pamahalaan ang nagtatakda ng sarili nilang '
            'clearance, bayad at validity. Nakalista sa entry ang karaniwang '
            'national na requirement at pinapaalalahanan kang kumpirmahin ang '
            'iba sa barangay hall ninyo.',
      ),
      InfoSection(
        'Mga pangalan ng lugar',
        'Ang rehiyon, probinsya, lungsod, munisipalidad at barangay ay galing '
            'sa Philippine Standard Geographic Code (PSGC) ng Philippine '
            'Statistics Authority, ginagamit sa ilalim ng CC BY 4.0 at '
            'nakatago sa app nang walang pagbabago. Ang postal code ay ayon sa '
            'PHLPost at per lungsod o munisipalidad, hindi per barangay.',
      ),
      InfoSection(
        'Mga lisensya',
        'Open source ang app at ang datos nito. Nasa Open-source licenses sa '
            'Settings ang listahan ng lisensya ng mga library.',
      ),
    ],
    disclaimer: [
      InfoSection(
        'Unofficial. Hindi app ng gobyerno.',
        'Proyektong pangkomunidad ang Kumpleto. Hindi ito app ng gobyerno, '
            'walang koneksyon sa kahit anong ahensya, at walang legal advice '
            'dito.',
      ),
      InfoSection(
        'Nagbabago ang requirements',
        'Binabago ng mga ahensya at ordinansa ang bayad, requirement at tagal '
            'ng proseso nang walang abiso. Pwedeng luma na ang isang entry '
            'kahit tama ito noong isinulat.',
      ),
      InfoSection(
        'Ano ang ibig sabihin ng "Unverified"',
        'Karamihan sa entries ay draft pa. Ibig sabihin ng badge, wala pang '
            'nagbabasa ng opisyal na source para sa entry na iyon. Ituring na '
            'simula lang ang bawat numero at listahan sa unverified na entry.',
      ),
      InfoSection(
        'Kumpirmahin bago gumastos',
        'Kumpirmahin sa ahensya o sa barangay hall bago magbayad, mag-book ng '
            'biyahe, o mag-file ng application. Ikaw ang may pananagutan sa mga '
            'desisyong gagawin mo gamit ang impormasyong ito.',
      ),
      InfoSection(
        'Walang warranty',
        'Ang datos ay ibinibigay kung ano ito, walang anumang warranty. Hindi '
            'mananagot ang mga maintainer sa anumang pagkalugi mula sa paggamit '
            'nito.',
      ),
    ],
    privacy: [
      InfoSection(
        'Walang account, walang sign-in',
        'Walang login, walang profile, at walang server na nakakaalam kung sino '
            'ka ang Kumpleto. Walang ireregister at walang ikakabit.',
      ),
      InfoSection(
        'Nasa telepono mo lang ang checklist',
        'Ang bawat tsek ay nakasulat sa lokal na database sa loob ng app. '
            'Hindi ito ina-upload, ini-sync, o ibinabahagi kahit kanino. Ganoon '
            'din ang wika, tema at lokasyong pinili mo.',
      ),
      InfoSection(
        'Walang tracking',
        'Walang analytics, walang advertising, walang crash reporting at '
            'walang third-party tracking SDK sa app.',
      ),
      InfoSection(
        'Kailan gumagamit ng network',
        'Dalawang bagay lang ang pwedeng gumamit ng internet, at ikaw ang '
            'nagsisimula sa dalawa: ang opsyonal na "Check for updates" sa '
            'Settings, at link na ikaw mismo ang tumap (halimbawa opisyal na '
            'source ng dokumento). Walang ipinapadalang impormasyon tungkol sa '
            'iyo ang update check.',
      ),
      InfoSection(
        'Pag-alis ng datos',
        'Ang Reset all progress sa Settings ay agad na nag-aalis ng lahat ng '
            'tsek. Kapag in-uninstall ang app, kasama na ring nabubura ang '
            'lokal na database, kaya tuluyan nang mawawala ang progress.',
      ),
    ],
  );
}

class _Content {
  const _Content({
    required this.about,
    required this.disclaimer,
    required this.privacy,
  });

  final List<InfoSection> about;
  final List<InfoSection> disclaimer;
  final List<InfoSection> privacy;
}
