# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were not surfaced as errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address logic or behavioral differences that may have been introduced during the migration.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific API calls that may compile but fail at runtime on non-Windows platforms.

```bash
dotnet add package Microsoft.Windows.Compatibility
```

If cross-platform support is required, replace or conditionally compile any Windows-only APIs.

## 5. Review NuGet Package Compatibility

Check that all NuGet dependencies target `netstandard2.0`, `netstandard2.1`, or the specific .NET version you are targeting. Packages that only support `net4x` may exhibit unexpected behavior.

```bash
dotnet list package --outdated
```

Update packages where newer, compatible versions are available.

## 6. Validate Configuration and App Settings

If the project uses configuration files (e.g., `App.config` or `Web.config`), confirm these have been migrated to `appsettings.json` or the appropriate .NET configuration model, as `App.config` support is limited in cross-platform .NET.

## 7. Test on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) to catch any runtime issues not surfaced during compilation:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assets are present before deploying.