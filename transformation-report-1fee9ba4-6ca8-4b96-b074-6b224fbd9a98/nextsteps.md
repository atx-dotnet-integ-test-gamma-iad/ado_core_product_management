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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update any outdated packages that have stable releases compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output for any test failures and address them before proceeding.

## 5. Validate Runtime Behavior

If there are no automated tests, manually exercise the core functionality of `AdoCore` to confirm:

- Database connections open and close correctly.
- Queries return expected results.
- Any ADO.NET-specific constructs (e.g., `DataAdapter`, `DataSet`, `DbCommand`) behave as expected on the new runtime.

## 6. Check for Platform-Specific Code

Search the codebase for any APIs that were Windows-only in .NET Framework and may behave differently or be unavailable in cross-platform .NET:

- `System.Data.OleDb` — only available on Windows in cross-platform .NET.
- `System.Data.Odbc` — available cross-platform but driver support varies by OS.
- Registry access or COM interop, if present.

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface these issues.

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm all required runtime assets are present before deploying to the target environment.