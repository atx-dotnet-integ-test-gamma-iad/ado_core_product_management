# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check all NuGet dependencies in `AdoCore.csproj` to confirm they are compatible with the target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger trx
```

Review the test results output and address any failing tests before proceeding.

## 5. Check for Removed or Changed APIs

Review the code for any usage of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.UpgradeAssistant` tool can help identify these:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze
```

Pay particular attention to:
- `System.Web` usages (not available in .NET Core/5+)
- Windows-specific APIs if cross-platform support is required
- Any reflection-based code that may behave differently

## 6. Validate Runtime Behavior

Run the application and exercise its primary workflows manually or through integration tests. Confirm that:
- Database connections (given the `AdoCore` name suggests ADO.NET usage) function correctly
- Connection strings are correctly configured for the new environment
- Any configuration files (e.g., `appsettings.json` replacing `app.config`/`web.config`) are properly set up

## 7. Check Configuration Migration

If the original project used `app.config` or `web.config`, verify that settings have been migrated to `appsettings.json` or environment variables. Confirm that `ConfigurationManager` usage, if any, references the `System.Configuration.ConfigurationManager` NuGet package:

```xml
<PackageReference Include="System.Configuration.ConfigurationManager" Version="8.0.0" />
```

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files are present, then deploy the contents of the `./publish` folder to the target environment.