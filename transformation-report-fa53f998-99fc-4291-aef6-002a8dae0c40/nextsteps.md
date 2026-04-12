# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version you intend to support.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages that may need updating.

## 3. Build the Solution

Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, as some may indicate compatibility concerns even if they do not block the build.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced during migration.

## 5. Validate Platform-Specific APIs

Review the codebase for any APIs that were previously Windows-only, such as those in `System.Windows.Forms`, `Microsoft.Win32`, or COM interop. Use the .NET Upgrade Assistant compatibility analyzer or the `dotnet-compatibility` tool to identify any remaining platform-specific calls:

```bash
dotnet tool install -g dotnet-compatibility
```

## 6. Check Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS as applicable) to confirm it behaves correctly at runtime. Build errors alone do not guarantee cross-platform compatibility, as some issues only surface at runtime.

## 7. Review `app.config` or `web.config` Migrations

If the original project used `app.config` or `web.config`, verify that configuration has been properly migrated to `appsettings.json` or environment-based configuration, as the legacy config system has limited support in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your target runtime identifier (RID) as needed, for example `win-x64` or `osx-x64`. Review the publish output directory to confirm all required assets are present.