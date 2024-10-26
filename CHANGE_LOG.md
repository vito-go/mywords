# v4.1.0
- Add translation button at the beginning of the sentence, which can translate the sentence. TODO: Add more languages.
# v4.0.0
- Rename package name from `com.example.mywords` to `com.mywords.android`.
- Initial version, ready to be launched on Google Play Store. Toady is a good day, 2024-10-19.
- Add GitHub link to the `About` dialog.

# v3.0.1
- **Real-Time synchronization (Beta)**:  Add a source parameter to the Go API functions to discriminate between web and client versions. So it can keep real-time synchronization between the two versions when one version updated the data.
- Due to the time difference between the underlying library and flutter, todayInt in flutter may be inaccurate, use the time of the underlying library, pass 1 to represent today
- Fix the display issue of WebDict API interface on web version.
- Make UI text more English-friendly
- Support copy of Email and copy of build information in about dialog.
- Upgrade dependencies to the latest version in go.mod.
- Remove the redundant code in the project. Optimize Makefile.
- Sensitive functions like `DelDict` are not allowed to be called in the web version when operating not in the local environment.
- Net proxy settings support configuration of username and password.
# v3.0.0
- The underlying code has been refactored to make it clearer. Using `sqlite` to store data, making the project more stable and easier to maintain.
- Mobile/desktop client version directly integrates Web, seamless learning between multiple devices. It called `Web Online` in the client version.
- Totally new design and user experience; Using English as the default language.
- Support for dark mode and light mode.
- Web support uploading super large (>2GB) dictionary files. Client version also supports uploading large files.
- Support for edit the name of the dictionary.
- Sharing  and Syncing data between devices is easier and faster.
