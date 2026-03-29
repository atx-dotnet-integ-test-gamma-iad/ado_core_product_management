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

Ensure there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific calls.

## 3. Run Existing Tests

If a test project exists in the solution, execute the test suite:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review the output for any failing tests that may indicate behavioral differences between the legacy .NET Framework version and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific APIs that may not behave correctly on Linux or macOS:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions
- COM interop or P/Invoke calls
- `System.Drawing` (replaced by cross-platform alternatives like `SkiaSharp`)

## 5. Review NuGet Package Compatibility

Check that all NuGet dependencies referenced in `AdoCore.csproj` have versions that support your target framework. You can inspect this with:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any packages that have newer cross-platform compatible versions available.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay attention to:
- File system path separators (`/` vs `\`)
- Case sensitivity in file paths on Linux
- Environment variable differences across operating systems

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific platform (e.g., Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files are present before deploying to the target environment.