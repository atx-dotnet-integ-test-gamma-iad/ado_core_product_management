# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee that runtime behavior is identical to the original .NET Framework version.

## 4. Verify Platform-Specific APIs

Review the codebase for any APIs that were available in .NET Framework but may behave differently or have reduced functionality in cross-platform .NET. Common areas to check include:

- `System.Drawing` (requires additional packages on Linux/macOS)
- `System.Web` (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- WCF server-side components
- `AppDomain` usage
- Reflection-based serialization

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 5. Run the Application

Execute the application directly to validate runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly those involving database access, file I/O, and any external service integrations, as these are common sources of runtime differences between .NET Framework and cross-platform .NET.

## 6. Review Target Framework Moniker (TFM)

Open `AdoCore.csproj` and confirm the `<TargetFramework>` value is set to an appropriate and currently supported version, such as `net8.0`:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the project is targeting `net6.0` or `net7.0`, consider upgrading to `net8.0` as those versions are out of support or approaching end of life.

## 7. Check for Removed or Changed Configuration Patterns

If the project previously used `App.config` or `Web.config`, verify that configuration has been migrated to `appsettings.json` and that `Microsoft.Extensions.Configuration` is being used where appropriate. The `ConfigurationManager` API is available via the `System.Configuration.ConfigurationManager` NuGet package if needed, but migrating to the modern configuration system is recommended.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).