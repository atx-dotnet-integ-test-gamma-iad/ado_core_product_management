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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Even without build errors, some .NET Framework APIs behave differently or have been removed in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility shims if needed. Pay particular attention to:

- `System.Data` and ADO.NET usage (relevant given the `AdoCore` project name)
- Any database provider packages (e.g., ensure you are using the correct cross-platform NuGet package for your database, such as `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient`)
- Configuration APIs (`ConfigurationManager` vs. `Microsoft.Extensions.Configuration`)

## 5. Validate NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure all packages target compatible versions for your chosen .NET runtime. Run:

```bash
dotnet list package --outdated
```

Update packages as appropriate and re-run the build and tests.

## 6. Perform Runtime Validation

Execute the application in a local environment that mirrors your target deployment environment. Confirm:

- Database connections are established correctly
- All ADO.NET queries return expected results
- Any platform-specific paths or configurations have been updated for cross-platform compatibility (e.g., use `Path.Combine` instead of hardcoded backslashes)

## 7. Publish the Application

Once runtime validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assemblies and configuration files are present.

## 8. Smoke Test the Published Output

Run the published output directly to confirm it operates correctly outside of the development environment:

```bash
dotnet ./publish/AdoCore.dll
```

Address any issues that surface during this final validation before deploying to your target environment.