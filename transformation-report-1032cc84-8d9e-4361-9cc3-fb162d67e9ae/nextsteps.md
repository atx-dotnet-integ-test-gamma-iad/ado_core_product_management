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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check that all `<PackageReference>` entries reference versions compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions available, particularly those that previously had Windows-only implementations.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any test failures before proceeding. Pay particular attention to tests that exercise database access, file I/O, or platform-specific APIs, as these are common sources of cross-platform runtime issues.

## 5. Validate Cross-Platform Behavior

If the intent is to run on non-Windows platforms, perform a test run on the target operating system (Linux or macOS):

```bash
dotnet run --configuration Release
```

Check for runtime exceptions related to:
- **Path separators**: Ensure `Path.Combine` is used rather than hardcoded `\` characters.
- **Case-sensitive file systems**: Linux file systems are case-sensitive; verify file and directory references match exactly.
- **Windows-specific APIs**: Any calls into `System.Windows`, COM interop, or the registry will fail on non-Windows platforms.

## 6. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to identify any API usage that may have changed between .NET Framework and modern .NET:

```bash
dotnet tool install -g dotnet-apicompat
```

Review the output and replace any incompatible API calls with their modern equivalents.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment target. Review the contents of the `publish` output folder to confirm all required assets are present before deploying to the target environment.