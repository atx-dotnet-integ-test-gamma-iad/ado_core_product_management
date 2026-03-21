# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that could not be resolved.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate compatibility issues at runtime.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 5. Validate Platform-Specific Behavior

Since this project involves ADO (ActiveX Data Objects) or data access components (suggested by the `AdoCore` name), verify the following:

- Any database connection strings are correct and accessible in the new environment.
- If the original project used `System.Data.OleDb` or similar Windows-only providers, confirm that either a cross-platform alternative has been substituted or that the `Microsoft.Windows.Compatibility` NuGet package has been added if Windows-only deployment is acceptable.
- Run integration or smoke tests against a real or test database instance to confirm data access works as expected.

## 6. Check for Runtime Configuration

Ensure an `appsettings.json` or equivalent runtime configuration file exists and contains the correct settings for your target environment. Legacy projects often relied on `App.config` or `Web.config`, which may need to be migrated to the new configuration system.

## 7. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, for example:

- `win-x64` for Windows 64-bit
- `linux-x64` for Linux 64-bit
- `osx-x64` for macOS 64-bit

Review the contents of the publish output directory to confirm all required assets are present before deploying to the target environment.