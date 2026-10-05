# CardLink – Android APK build pack (GitHub Actions)

You do NOT need Flutter or Android Studio on your computer. GitHub builds the APK for you, free.

## What this version does
- Scan a paper business card -> on-phone OCR -> review/edit -> Save to phone Contacts (no account needed)
- "Try a sample card (demo)" button on the Scan tab, to test without a real card
- Create My Digital Card (stored on the phone), QR code, share as .vcf contact file
- Settings: privacy note and "Delete all my data"

NOT in this version yet (next pack): online account, Supabase, public web card page, QR that opens a web page.

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

## Settings (no secrets in code)
The QR link's website address is set outside the code:
GitHub repository -> Settings -> Secrets and variables -> Actions -> Variables tab -> New repository variable
Name: PUBLIC_BASE_URL   Value: https://yourdomain.com   (no slash at the end)
Rebuild afterwards. Until you set it, the app shows a placeholder address. No API keys are needed for this version.

## If the build fails (red cross)
Open the failed run, click the red step, copy the last ~40 lines of the log and send them back.
This pack could not be compiled where it was written, so a first-run fix is possible.

## Notes
- The APK is signed with a debug key: fine for your own phone, NOT for Google Play. Play Store signing comes later.
- iOS is not built here (needs a Mac and an Apple developer account).
