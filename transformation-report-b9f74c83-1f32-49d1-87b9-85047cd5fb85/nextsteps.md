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

Review the output for any warnings that could indicate compatibility issues, even if they are not hard errors.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions that are compatible with the target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to identify any APIs that may have been removed or changed between the legacy .NET Framework and the current .NET version:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- `AppDomain` members with limited support
- Reflection APIs that have changed behavior
- Any Windows-specific APIs if cross-platform support is required

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they indicate a behavioral difference introduced by the migration.

## 6. Validate Runtime Behavior

Run the application and exercise its primary workflows manually or through integration tests. Confirm that:
- Database connections (if any ADO.NET usage is present, given the `AdoCore` project name) function correctly with the updated data provider packages.
- Connection strings are correctly configured for the new environment.
- Any configuration previously stored in `App.config` or `Web.config` has been migrated to `appsettings.json` or environment variables, as `System.Configuration` has limited support in cross-platform .NET.

## 7. Check Configuration Migration

If the project previously relied on `System.Configuration.ConfigurationManager`, verify that either:
- The `System.Configuration.ConfigurationManager` NuGet package has been added, or
- Configuration has been migrated to `Microsoft.Extensions.Configuration` with `appsettings.json`.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files and dependencies are present before deploying to the target environment.