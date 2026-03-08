# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

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

Verify that no warnings are being treated as errors and that all projects compile cleanly.

## 3. Run Existing Tests

If the solution contains test projects, execute them to confirm that existing functionality is preserved after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Pay attention to the following areas:

- **Windows-specific APIs**: Any usage of `System.Windows.Forms`, `System.Drawing`, or COM interop may require the `<UseWindowsForms>` or `<UseWPF>` flags, or may not be available on non-Windows platforms.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only.
- **File path separators**: Ensure paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than hardcoded backslashes.
- **Configuration**: If the project previously used `App.config` or `Web.config`, verify that configuration has been migrated to `appsettings.json` or another supported mechanism.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions that support your target framework. You can audit this with:

```bash
dotnet list package --outdated
```

Replace any packages that target only `net45` or similar legacy monikers with their modern equivalents where available.

## 6. Validate ADO-Specific Functionality

Given the project name `AdoCore`, it likely involves ADO.NET data access. Confirm the following:

- Connection strings are correctly configured for the target environment.
- Any usage of `System.Data.OleDb` is noted, as this is Windows-only in .NET Core and later.
- `System.Data.SqlClient` should be replaced with `Microsoft.Data.SqlClient` if not already done, as the former is no longer actively maintained.

```bash
dotnet add package Microsoft.Data.SqlClient
```

## 7. Perform Integration and Smoke Testing

After unit tests pass, run the application against a real or representative data source to validate end-to-end behavior. Focus on:

- Database connectivity and query execution
- Any data type mappings that may differ between runtimes
- Exception handling paths

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.