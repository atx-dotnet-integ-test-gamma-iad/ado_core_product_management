# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

## 3. Review NuGet Package Versions

Check all `<PackageReference>` entries in `AdoCore.csproj` to ensure the referenced packages have versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs behave differently or are unsupported on non-Windows platforms. Review the code for usage of the following, which are common problem areas in ADO-related projects:

- `System.Data.OleDb` — only supported on Windows.
- `System.Data.Odbc` — limited cross-platform support.
- `Microsoft.Win32` namespaces — Windows-only.
- Registry access — Windows-only.

If cross-platform support is a requirement, replace or conditionally compile any Windows-specific code paths.

## 6. Test Against a Real Database

Since this is an ADO-related project, validate database connectivity and query execution against your target database engine. Confirm:

- Connection strings are correctly configured for the new environment.
- Any `DbProviderFactory` usage resolves correctly, as provider registration changed between .NET Framework and .NET.
- Transactions, stored procedure calls, and data reader behavior are consistent with the legacy implementation.

## 7. Validate Configuration Files

.NET no longer uses `App.config` or `Web.config` in the same way as .NET Framework. Confirm that:

- Any connection strings or app settings have been migrated to `appsettings.json` or environment variables if applicable.
- If `App.config` is still present, verify it is being read correctly using `System.Configuration.ConfigurationManager` via the `System.Configuration.ConfigurationManager` NuGet package.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all necessary runtime files and dependencies are present before deploying to the target environment.