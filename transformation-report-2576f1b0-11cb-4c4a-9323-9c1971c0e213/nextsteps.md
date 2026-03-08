# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. If any packages are flagged, check NuGet.org for updated versions and replace them in the `.csproj` file.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings, particularly those related to nullable reference types, obsolete APIs, or platform compatibility analyzers (e.g., `CA1416`).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test results carefully. Any failing tests should be investigated to determine whether they indicate a behavioral regression introduced during migration.

## 5. Check for Platform-Specific API Usage

Since this project was migrated from a legacy .NET Framework project, audit the code for any APIs that are Windows-specific and may not function correctly on Linux or macOS. Common areas include:

- `System.Windows.Forms` or `System.Drawing` (GDI+)
- `Microsoft.Win32` registry access
- COM interop
- Windows-specific file path assumptions (e.g., backslashes, drive letters)

The .NET Upgrade Assistant and the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) can assist in identifying these usages.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement:

```bash
dotnet run --configuration Release
```

Test all major code paths, particularly those that previously relied on .NET Framework-specific behavior such as `AppDomain`, `Remoting`, or `ConfigurationManager`.

## 7. Review Configuration Files

If the project previously used `App.config` or `Web.config`, verify that configuration has been migrated to `appsettings.json` or environment variables, and that `Microsoft.Extensions.Configuration` is being used where appropriate.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (RID) for your deployment target (e.g., `linux-x64`, `osx-x64`). Review the contents of the `publish` output folder to confirm all required assets are present before deploying.