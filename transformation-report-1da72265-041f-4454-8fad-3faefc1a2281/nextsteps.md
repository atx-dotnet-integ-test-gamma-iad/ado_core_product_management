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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions that are compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently or have been removed in cross-platform .NET compared to .NET Framework. Review the following areas manually:

- Any usage of `System.Web` (not available in cross-platform .NET)
- `AppDomain`, `Remoting`, or `BinaryFormatter` usage
- Windows-specific registry or file path assumptions
- Any P/Invoke calls that may be platform-specific

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package if needed.

## 5. Run Existing Tests

If the solution contains a test project, execute the tests to validate runtime behavior:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output for any failed or skipped tests. Address any failures before proceeding.

## 6. Perform Runtime Smoke Testing

Run the application locally and exercise the primary code paths of `AdoCore`:

```bash
dotnet run --project AdoCore --configuration Release
```

If `AdoCore` is a library, write or run a small console application or test harness that exercises its public API to confirm expected behavior.

## 7. Validate Database Connectivity (If Applicable)

Since the project name suggests ADO.NET usage, confirm that:

- Connection strings are correctly configured for the target environment
- The database provider NuGet package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`) is the correct cross-platform compatible version
- Any `DbProviderFactory` registrations that were previously in `machine.config` or `app.config` are now handled in code or `appsettings.json`

## 8. Review Configuration Files

Ensure that any `app.config` or `web.config` settings have been migrated to `appsettings.json` or environment variables where appropriate, as these formats are the standard for cross-platform .NET applications.

## 9. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.