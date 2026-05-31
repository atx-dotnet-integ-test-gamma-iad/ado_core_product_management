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

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Run the application and exercise its primary code paths to check for:

- `PlatformNotSupportedException` — certain APIs that existed in .NET Framework are not available on all platforms in .NET.
- `TypeLoadException` or `MissingMethodException` — can occur if a dependency has not been fully updated.
- File path separator differences between Windows (`\`) and Unix (`/`) if cross-platform execution is intended.

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. For each package:

- Confirm the version supports your target framework by checking [nuget.org](https://www.nuget.org).
- Replace any packages that target only `net4x` with their cross-platform equivalents if cross-platform support is a goal.

```bash
dotnet list package --outdated
```

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as `System.Configuration.ConfigurationManager` behavior differs in .NET.

## 7. Perform a Release Build and Publish

Once validation is complete, publish the application:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files and dependencies are present.

## 8. Test the Published Output

Run the published output directly to confirm it behaves identically to the build output:

```bash
dotnet ./publish/AdoCore.dll
```

Or, if published as a self-contained executable:

```bash
./publish/AdoCore
```