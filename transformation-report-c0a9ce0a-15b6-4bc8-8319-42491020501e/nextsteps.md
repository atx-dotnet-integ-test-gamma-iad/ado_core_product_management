# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

### 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while non-blocking, may indicate compatibility concerns worth addressing.

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review test results carefully. A successful build does not guarantee that all runtime logic behaves identically after migration.

### 4. Verify Target Framework

Open `AdoCore.csproj` and confirm that the `<TargetFramework>` element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the runtime environment where the application will be deployed.

### 5. Review Removed or Changed APIs

Check for any use of APIs that were available in .NET Framework but have changed behavior or limited support in cross-platform .NET. Pay particular attention to:

- `System.Web` references (not available in .NET Core and later)
- Windows-specific APIs such as the registry, WCF server-side components, or `System.Drawing` without the compatibility package
- Any `app.config` or `web.config` sections that may need to be migrated to `appsettings.json` or environment-based configuration

### 6. Test on Target Platform

If the intent of the migration is to run on a non-Windows operating system, run the application on that platform explicitly. Some APIs have platform-specific implementations that only surface issues at runtime on Linux or macOS.

```bash
dotnet run --configuration Release
```

### 7. Review NuGet Package Compatibility

Inspect all referenced NuGet packages and confirm they support the target framework. Packages that have not been updated in several years may only support .NET Framework. Use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer, compatible versions are available.

### 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm that all required assets, configuration files, and dependencies are present before deploying to the target environment.