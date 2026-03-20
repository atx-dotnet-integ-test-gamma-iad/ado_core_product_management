# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Even without build errors, some .NET Framework APIs behave differently or have been removed in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to scan for runtime-level compatibility issues:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <path-to-solution>
```

## 5. Review NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure all packages are updated to versions that support your target framework. You can check for outdated packages with:

```bash
dotnet list package --outdated
```

Update packages as needed and re-run the build and tests.

## 6. Validate Platform-Specific Behavior

If `AdoCore` interacts with databases, file systems, or Windows-specific APIs (e.g., registry, COM interop, `System.Data` with OLE DB providers), test these code paths explicitly on your target platform. Some providers, such as OLE DB, are not supported on Linux or macOS.

## 7. Run the Application

Execute the application directly to perform a basic smoke test:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Verify that the application starts and behaves as expected.

## 8. Publish the Application

Once validation is complete, publish the application for deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).

## 9. Review Output Artifacts

Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and assets are present before deploying to the target environment.