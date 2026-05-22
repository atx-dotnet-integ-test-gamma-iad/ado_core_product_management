# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

Review the output for any warnings that may indicate deprecated APIs or packages that were not caught as errors.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions compatible with your target framework. You can check for outdated packages with:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and modern .NET.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been removed or behave differently on cross-platform .NET. Search the codebase for usages of the following common problem areas:

- `System.Web` (not available on .NET Core/.NET 5+)
- `System.Runtime.Remoting`
- `BinaryFormatter` (deprecated and disabled by default)
- Windows Registry APIs (`Microsoft.Win32.Registry`) — these will only function on Windows
- `AppDomain.CreateDomain` (not supported)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to assist with this review.

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear as build errors.

```bash
dotnet run --configuration Release
```

## 7. Review Configuration Files

If the legacy project used `App.config` or `Web.config`, verify that settings have been migrated to `appsettings.json` or environment variables as appropriate for modern .NET applications.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the contents of the publish output folder before deploying to the target environment.