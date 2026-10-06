# CardLink – Android APK build pack (GitHub Actions)

You do NOT need Flutter or Android Studio on your computer. GitHub builds the APK for you, free.

## What this version does
- Scan a paper business card -> on-phone OCR -> review/edit -> Save to phone Contacts (no account needed)
- "Try a sample card (demo)" button on the Scan tab, to test without a real card
- Create My Digital Card (stored on the phone). Its QR code contains the contact details directly (standard vCard),
  so any phone camera can read it, with no internet, website or account. Also share the QR image or a .vcf file.
- Settings: privacy note and "Delete all my data"

By design there is no online account, database or website: nothing to pay for and nothing that can go offline.
Trade-off: a QR cannot be updated after it is shared. If your details change, show your new QR.

## Step 1 - Put the files on GitHub
1. Create a free account at github.com. Click New repository. Name it `cardlink`. Choose Private. Create it.
2. Unzip this pack on your computer.
3. In the new repository click "uploading an existing file". Open the unzipped folder and drag in EVERYTHING
   inside it (pubspec.yaml, lib, README.md, .gitignore, WORKFLOW_COPY_build-apk.yml.txt ...).
   Do not upload the .zip itself.
4. Click "Commit changes".

## Step 2 - Make sure the build recipe is there
Hidden folders (starting with a dot) are sometimes skipped by the browser. Check that the repository
shows a folder `.github/workflows/` containing `build-apk.yml`. If not:
1. Click Add file -> Create new file.
2. In the name box type exactly:  .github/workflows/build-apk.yml
3. Open WORKFLOW_COPY_build-apk.yml.txt, copy everything, paste it into the big box.
4. Click Commit changes.

## Step 3 - Build
Committing to the `main` branch starts a build automatically.
1. Open the Actions tab. Click the newest run ("Build Android APK"). Wait about 5-10 minutes for a green tick.
2. Scroll down to Artifacts and click `cardlink-apk`. It downloads a zip containing `app-release.apk`.
To rebuild later: Actions -> Build Android APK -> Run workflow.

## Step 4 - Install on your Android phone
1. Unzip the download, send app-release.apk to your phone (USB, email, Drive, WhatsApp to yourself).
2. Tap it. Android will ask to allow installing from this source - allow it.
3. If Play Protect warns about an unknown app, choose "Install anyway". This is normal for apps not from the Play Store.

## If the build fails (red cross)
Open the failed run, click the red step, copy the last ~40 lines of the log and send them back.
This pack could not be compiled where it was written, so a first-run fix is possible.

## Notes
- The APK is signed with a debug key: fine for your own phone, NOT for Google Play. Play Store signing comes later.
- iOS is not built here (needs a Mac and an Apple developer account).

---
# iOS (iPhone) build

Workflow: `.github/workflows/build-ios.yml` (copy: WORKFLOW_COPY_build-ios.yml.txt). It is MANUAL only:
Actions tab -> "Build iOS (unsigned IPA)" -> Run workflow. Takes roughly 10-20 minutes.
Result: artifact `cardlink-ios-unsigned-ipa` containing `CardLink-unsigned.ipa`.

IMPORTANT: this IPA is UNSIGNED. An iPhone will not install it directly. Apple requires apps to be signed.

## Way 1 - free, for your own iPhone (testing): sideload with a free Apple ID
1. Install Sideloadly (sideloadly.io) or AltStore on a Mac or Windows computer.
2. Connect the iPhone by cable, unlock it, tap "Trust".
3. On iPhone 16+ iOS: Settings -> Privacy & Security -> Developer Mode -> On (phone restarts).
4. Drag CardLink-unsigned.ipa into Sideloadly, enter your Apple ID, click Start.
5. On the iPhone: Settings -> General -> VPN & Device Management -> your Apple ID -> Trust.
Limits of a free Apple ID: the app stops working after 7 days and must be re-installed the same way;
only a few sideloaded apps at a time. Sideloadly/AltStore are third-party tools that sign in with your Apple ID.

## Way 2 - for public release: Apple Developer Program (paid, about US$99/year)
Needed for TestFlight and the App Store. After joining, the workflow is extended with signing secrets
so GitHub builds a signed app you can upload. (Not included yet.)

## Cost note
Public GitHub repository: macOS builds are free. Private repository: a macOS build uses about 10x the minutes of an Android build
from your monthly free allowance (2,000 minutes, so roughly 200 macOS minutes).

---
# Web version (works on any phone or computer, no store needed)

Workflow: `.github/workflows/build-web.yml` (copy: WORKFLOW_COPY_build-web.yml.txt).
It builds the same app as a website. Result: artifact `cardlink-web` (the website files), and the same files on a branch called `web-build`.

Differences from the phone app (a website is not allowed to do these things):
- Scan: take/choose a photo (no live auto-crop). Text is read inside the browser (Tesseract.js, loaded from the internet on first use).
- Save to Contacts: downloads a .vcf file; the phone then offers "Add to Contacts".
- Saved scans and your card are stored in that browser only. Clearing browser data deletes them.

## Put it online with Cloudflare Pages (free)
1. GitHub -> Actions -> newest "Build Web App" run -> Artifacts -> download `cardlink-web`, and unzip it.
2. Cloudflare dashboard -> Workers & Pages -> Create -> Pages -> Upload assets (Direct Upload).
3. Give the project a name (it becomes name.pages.dev), drag in the unzipped files, click Deploy.
4. Open the address on your phone. To install: iPhone Safari -> Share -> Add to Home Screen. Android Chrome -> menu -> Install app.
To update later: download the new artifact and upload it again as a new deployment.
