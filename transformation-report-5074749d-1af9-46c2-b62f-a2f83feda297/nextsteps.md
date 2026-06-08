# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a full build to confirm there are no issues beyond what was captured in the transformation output:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate subtle behavioral differences from the original .NET Framework code.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release
```

Pay close attention to any tests that interact with Windows-specific APIs, file system paths, or registry access, as these areas are common sources of cross-platform failures that do not always produce build errors.

## 5. Check for Runtime Dependencies

Review the code for any remaining usage of:

- `System.Web` namespaces
- Windows registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls targeting Windows-only libraries
- `AppDomain` APIs that behave differently on .NET 5+

These will not necessarily cause build errors but can cause runtime failures on non-Windows platforms.

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, as the `ConfigurationManager` behavior differs between .NET Framework and modern .NET.

## 7. Test on Target Platforms

Run the application on each operating system you intend to support (Linux, macOS, Windows) to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the output directory to confirm all required assets and dependencies are present before deploying.