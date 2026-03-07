# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are present but throw `PlatformNotSupportedException` at runtime on non-Windows platforms:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Drawing` (GDI+)
- COM interop

## 5. Validate NuGet Package Compatibility

Review the packages referenced in `AdoCore.csproj` and confirm each one targets a compatible framework. Packages that only support `net45` or `netstandard1.x` may function but could produce runtime issues.

```bash
dotnet list package --outdated
```

Update any outdated packages where a newer version with .NET 6/7/8 support is available.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application or test suite on each intended target operating system (Windows, Linux, macOS) to surface any OS-specific runtime failures that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 7. Review Output Artifacts

Confirm the output directory contains the expected assemblies and that no legacy `.config` files (e.g., `app.config` with `<startup>` elements) are being incorrectly carried forward. In .NET 5+, `app.config` support is limited and `appsettings.json` is the preferred configuration mechanism.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) as needed. Review the contents of the `publish` output folder before deploying to the target environment.