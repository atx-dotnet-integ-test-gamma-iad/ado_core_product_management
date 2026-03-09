# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced by the restored packages:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate potential runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after the migration:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new .NET runtime.

## 5. Check for Platform-Specific API Usage

Since this project involves ADO (ActiveX Data Objects) or similar data access components, verify that any data access APIs used in `AdoCore` are supported on cross-platform .NET. Specifically:

- If the project uses `System.Data.OleDb`, note that this is **Windows-only** on .NET Core/.NET 5+. Consider replacing it with a cross-platform alternative such as `Microsoft.Data.SqlClient` for SQL Server, or the appropriate provider for your database.
- If `System.Data.Odbc` is used, it is available cross-platform but may require additional driver configuration on non-Windows systems.

## 6. Validate Runtime Behavior

Run the application manually or through integration tests against a real or representative data source to confirm that data access operations behave as expected:

```bash
dotnet run --project AdoCore --configuration Release
```

Compare the output or behavior against the legacy application to identify any regressions.

## 7. Review Removed or Changed APIs

Consult the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [.NET API compatibility tool](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/api-analyzer) to identify any APIs that were available in .NET Framework but have changed or been removed in the target .NET version.

## 8. Update Assembly and Package References

Open the `.csproj` file and confirm that all `<PackageReference>` entries are pointing to current, stable versions. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages as appropriate, testing after each update to isolate any issues.

## 9. Confirm Output Artifacts

After a successful Release build, verify that the output directory contains the expected assemblies and that the application runs correctly from the build output:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required files are present.