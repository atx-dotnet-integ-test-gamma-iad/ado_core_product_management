# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it does not match your intended target, update it and rebuild the solution.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are correctly restored:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages and update them as needed using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet clean
dotnet build --configuration Release
```

Address any warnings that appear, as some may indicate runtime issues even if the build succeeds.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --verbosity normal
```

Review the test output carefully. Any failing tests should be investigated and resolved before proceeding.

## 5. Validate Runtime Behavior

Run the application locally and exercise its primary workflows to confirm runtime behavior matches expectations from the legacy version:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Pay particular attention to:
- Database connectivity and ADO.NET operations, given the project name suggests data access logic.
- Any platform-specific APIs that may have been present in the legacy project (e.g., Windows registry access, COM interop, or `System.Windows` dependencies) which may compile but fail at runtime on non-Windows platforms.

## 6. Check for Platform-Specific Runtime Issues

Even with a successful build, certain APIs behave differently or throw `PlatformNotSupportedException` at runtime on Linux or macOS. Review the code for usage of:

- `System.Data.OleDb` (Windows-only)
- `System.Data.Odbc` (limited cross-platform support)
- Windows-specific connection string providers

If any of these are present, consider replacing them with cross-platform alternatives such as the appropriate provider-specific NuGet packages (e.g., `Microsoft.Data.SqlClient` for SQL Server).

## 7. Review Configuration Files

Ensure that any configuration previously stored in `App.config` or `Web.config` has been migrated to `appsettings.json` or environment variables, as the legacy XML-based configuration system has limited support in modern .NET:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "your-connection-string-here"
  }
}
```

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Review the contents of the `publish` output folder to confirm all required files are present before deploying to the target environment.