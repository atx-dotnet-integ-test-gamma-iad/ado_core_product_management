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

Check all `<PackageReference>` entries in `AdoCore.csproj` and any other projects in the solution. Confirm that:

- No packages are pinned to versions targeting only .NET Framework.
- Packages have stable, non-prerelease versions unless a prerelease is intentionally required.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET.

## 5. Check for Platform-Specific API Usage

Search the codebase for APIs that were available in .NET Framework but are absent or behave differently in modern .NET. Common areas to inspect include:

- `System.Web` references (not available in modern .NET)
- `AppDomain` usage
- Remoting or binary serialization
- Windows Registry access (`Microsoft.Win32.Registry`)
- `ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to surface any remaining compatibility issues.

## 6. Test on Target Operating Systems

Since the project is now cross-platform, validate it on each operating system you intend to support (Windows, Linux, macOS) by running:

```bash
dotnet run --configuration Release
```

Pay attention to:

- File path separator differences (`\` vs `/`)
- Case sensitivity in file system operations on Linux
- Platform-specific environment variables

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) as needed. Review the output in the `publish` folder before deploying to your target environment.

## 8. Review Output Type and Entry Point

If `AdoCore` is a library, confirm the `<OutputType>` is not set to `Exe`. If it is an executable, verify the entry point (`Main` method or top-level statements) is present and correct.