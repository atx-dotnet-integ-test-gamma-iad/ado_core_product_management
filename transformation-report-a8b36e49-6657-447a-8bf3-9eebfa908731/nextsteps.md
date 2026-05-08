# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment of the migrated project.

## 1. Review the Migrated Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to Windows-only assemblies (e.g., `System.Web`, `System.Windows.Forms`) have been replaced with appropriate NuGet packages or removed.
- The `<Nullable>` and `<ImplicitUsings>` settings reflect your team's preferences.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them in the `.csproj` file as needed.

## 3. Build the Solution

Perform a clean build to confirm there are no issues introduced after restore:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete API usage, as these can indicate areas that may cause runtime issues.

## 4. Run the Existing Test Suite

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Validate Platform-Specific Behavior

If the original project relied on any of the following, verify that the cross-platform equivalents function correctly on your target operating system:

- File path handling (`Path.Combine` vs. hardcoded separators)
- Registry access (`Microsoft.Win32.Registry`) — this is Windows-only and will require conditional compilation or an alternative approach on Linux/macOS
- Windows-specific authentication or security APIs
- COM interop or P/Invoke calls

Use `RuntimeInformation.IsOSPlatform()` to guard any platform-specific code paths where necessary.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) and verify:

- Application startup completes without exceptions
- Core functionality produces consistent results across platforms
- File I/O, networking, and configuration loading behave as expected

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

**Framework-dependent (requires .NET runtime installed on the target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime with the application):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) for your target platform.

## 8. Verify the Published Output

Navigate to the `./publish` directory and confirm:

- The expected executable or DLL is present
- Any required configuration files (e.g., `appsettings.json`) are included
- The application runs correctly from the published output directory

```bash
dotnet ./publish/AdoCore.dll
```