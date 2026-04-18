# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check all `<PackageReference>` entries in `AdoCore.csproj` and any other projects in the solution. Confirm that the referenced packages have versions compatible with your target framework. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and the cross-platform .NET equivalents.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been silently replaced or may behave differently on non-Windows platforms. Review the code for usage of:

- `System.Windows.Forms` or `System.Drawing` (requires additional packages on non-Windows)
- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls
- `AppDomain` usage that is not supported in .NET Core and later

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining compatibility concerns.

## 6. Test on Target Platform

If the goal is cross-platform support, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at build time.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with your target runtime identifier (e.g., `win-x64`, `osx-x64`). Review the output in the `publish` folder before deploying to your target environment.