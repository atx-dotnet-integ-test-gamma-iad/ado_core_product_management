# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific API calls that may fail on non-Windows platforms. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay attention to analyzer warnings prefixed with `CA1416` (platform compatibility).

## 5. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Test all major code paths, particularly those involving:

- File I/O and path handling (`Path.Combine` vs hardcoded separators)
- Registry access (Windows-only)
- COM interop (Windows-only)
- `System.Drawing` (requires additional packages on non-Windows)

## 6. Review NuGet Package Versions

Open the `.csproj` file and verify that all NuGet dependencies reference versions compatible with your target framework. Use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and re-run the build and tests after each update.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Review the contents of the `publish` output folder before deploying.