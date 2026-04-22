# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime available in your target environment.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not block the build.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior matches expectations after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform .NET equivalents.

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining platform-specific API calls that may not behave correctly on non-Windows operating systems. This can be done by adding the following to your `.csproj` if not already present:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

Rebuild and review any new analyzer warnings.

## 5. Validate NuGet Package Compatibility

Review all NuGet dependencies and confirm they target `netstandard2.0`, `netstandard2.1`, or a compatible .NET version. Packages that only target `net4x` may still function via compatibility shims but should be replaced with actively maintained alternatives where possible.

```bash
dotnet list package --outdated
```

## 6. Functional and Integration Testing

Execute any available integration or end-to-end tests against a staging environment. Pay particular attention to:

- Database connectivity and ADO.NET behavior, given the project name suggests ADO usage.
- Connection string formats, as some providers have changed defaults in cross-platform .NET.
- Any file system paths that may have been hardcoded using Windows-style separators (`\`). Replace these with `Path.Combine` or forward slashes where applicable.

## 7. Review Configuration Files

If the project previously used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables, as `System.Configuration` support is limited in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm all required runtime assets and dependencies are present before deploying to your target environment.