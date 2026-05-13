# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

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

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Web` references
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- COM interop or P/Invoke calls targeting Windows-specific libraries
- `BinaryFormatter` (deprecated and disabled by default in modern .NET)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling if needed.

## 5. Validate NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions that support the target framework. Open the `.csproj` file and review `<PackageReference>` entries. You can also run:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling (`Path.Combine` vs hardcoded separators), line ending differences, and case-sensitive file systems on Linux.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform (e.g., Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` folder to confirm all required files are present before deploying to the target environment.