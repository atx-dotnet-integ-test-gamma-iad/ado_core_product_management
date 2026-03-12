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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by API differences between .NET Framework and modern .NET.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs that existed in .NET Framework may have changed behavior or have limited support on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the following command to check for platform compatibility issues:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to areas such as:
- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Registry access
- Windows-specific threading or security APIs

## 6. Validate ADO.NET / Database Connectivity

Given the nature of the `AdoCore` project, verify that all database connection strings, providers, and driver packages are correctly configured for cross-platform use. Confirm that the database driver NuGet package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is explicitly referenced and is a version that supports your target framework.

Test actual database connectivity in a non-production environment before proceeding further.

## 7. Run the Application

Execute the application directly to confirm runtime behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Monitor the output for any runtime exceptions that would not have surfaced at build time.

## 8. Publish the Application

Once the above validation steps pass, publish the application for your target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

If targeting a specific runtime, include the runtime identifier:

```bash
dotnet publish --configuration Release -r linux-x64 --self-contained false --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files are present before deploying to your target environment.