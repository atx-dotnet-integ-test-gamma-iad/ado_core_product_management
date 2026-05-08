# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`). Example:

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the original .NET Framework project. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- `System.Security.Permissions`
- COM interop or P/Invoke calls

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where replacements are needed.

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm that each package version supports the target framework. You can verify compatibility on [nuget.org](https://www.nuget.org) by checking the listed supported frameworks for each package.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended platform (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and environment-specific configuration values.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific platform (e.g., Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish-linux
```

Review the contents of the output directory to confirm all required files are present before deploying.