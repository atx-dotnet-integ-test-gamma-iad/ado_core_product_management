# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Review any usages of APIs that were available in .NET Framework but have been removed or altered in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling can assist with this.

Pay particular attention to:
- `System.Data` and ADO.NET-related APIs if this project deals with data access
- Any Windows-specific APIs (e.g., registry access, WCF, `System.Drawing`)

## 5. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output for any failures or unexpected results.

## 6. Perform Runtime Smoke Testing

Run the application or exercise the library's primary code paths manually or through integration tests to confirm there are no runtime exceptions that would not surface at build time.

## 7. Validate Platform-Specific Behavior

Since this is a cross-platform migration, test the application on each target operating system (Windows, Linux, macOS) if applicable:

```bash
dotnet run --configuration Release
```

Confirm that file paths, line endings, and any environment-dependent logic behave correctly on each platform.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust `--runtime` as needed (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 9. Review Output Artifacts

Inspect the `publish` output directory to confirm all required assemblies, configuration files, and assets are present before deploying to the target environment.