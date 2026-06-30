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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions that are compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that previously targeted `.NET Framework`.

## 4. Check for Removed or Changed APIs

Some APIs available in .NET Framework are not available or have changed in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any runtime-level compatibility concerns:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution-file>.sln
```

## 5. Run Existing Tests

If the solution contains test projects, execute them to confirm existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether failures are due to the migration or pre-existing issues.

## 6. Validate Platform-Specific Behavior

Since the project is now cross-platform, verify the following areas manually if they are relevant to `AdoCore`:

- **File paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) exist in the code.
- **Database connectivity**: If the project uses ADO.NET, confirm that the database drivers (e.g., `Microsoft.Data.SqlClient`) are compatible with the target OS.
- **Configuration**: Confirm that any `app.config` or `web.config` settings have been migrated to `appsettings.json` or environment variables where appropriate.
- **Registry access**: Registry-based code will not function on Linux/macOS and must be replaced with an alternative configuration mechanism.

## 7. Test on Target Platform

If the intended deployment target is Linux or macOS, run the application on that platform explicitly to catch any OS-specific runtime issues that would not surface on Windows:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# For a self-contained Linux x64 deployment
dotnet publish -c Release -r linux-x64 --self-contained true

# For a framework-dependent Windows x64 deployment
dotnet publish -c Release -r win-x64 --self-contained false
```

Review the contents of the `publish` output folder to confirm all required assets are present before deploying.