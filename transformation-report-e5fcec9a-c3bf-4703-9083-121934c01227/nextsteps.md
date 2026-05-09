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

Update any packages that have newer stable versions available, particularly those that were previously Windows-specific and may have cross-platform alternatives.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

If no tests currently exist, consider writing unit tests for the core functionality in `AdoCore` before proceeding further.

## 5. Check for Platform-Specific Code

Even without build errors, there may be runtime-only platform-specific calls (e.g., Windows registry access, `System.Drawing` on non-Windows, or P/Invoke calls). Search the codebase for the following:

- `Registry` usage from `Microsoft.Win32`
- `System.Drawing` types (use `SkiaSharp` or `ImageSharp` as cross-platform alternatives)
- Any `[DllImport]` attributes targeting Windows-only native libraries

## 6. Test on Target Platforms

Run the application on each platform you intend to support (e.g., Linux, macOS, Windows) to surface any platform-specific runtime exceptions that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# For a self-contained Linux x64 publish
dotnet publish -c Release -r linux-x64 --self-contained true

# For a framework-dependent Windows x64 publish
dotnet publish -c Release -r win-x64 --self-contained false
```

Review the contents of the `publish` output folder to confirm all required assets and dependencies are present before deploying to the target environment.