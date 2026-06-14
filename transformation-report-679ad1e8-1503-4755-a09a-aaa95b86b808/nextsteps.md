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

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available using:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

## 4. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to identify any APIs used in the code that have been removed or changed in the target framework version.

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to:
- `System.Data` and ADO.NET-related APIs if this project interacts with databases
- Any platform-specific APIs that were previously available only on Windows

## 5. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests to determine whether they reflect regressions introduced during migration or pre-existing issues.

## 6. Perform Runtime Smoke Testing

Run the application locally and exercise its primary functionality manually. Confirm that:
- Database connections (if applicable) are established correctly
- Data read/write operations behave as expected
- Any configuration files (e.g., `appsettings.json`) are being loaded correctly

## 7. Validate Cross-Platform Behavior

If cross-platform support is a goal, test the application on each target operating system (Windows, Linux, macOS) to identify any platform-specific issues such as:
- File path separator differences
- Case-sensitive file system behavior on Linux
- Platform-specific dependencies that may not be available

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your target runtime identifier (e.g., `win-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required files are present before deploying.