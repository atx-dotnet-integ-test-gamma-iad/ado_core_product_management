# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy the migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

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

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new .NET runtime.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-only API calls that may not be apparent from build errors alone. Run the following if the analyzer is available:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Address any diagnostics related to platform compatibility, particularly those prefixed with `CA1416`.

## 5. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm runtime behavior is consistent:

```bash
dotnet run --configuration Release
```

Pay close attention to:
- File path handling (`Path.Combine` vs hardcoded separators)
- Registry access (Windows-only)
- `System.Drawing` usage (requires `libgdiplus` on Linux/macOS or migration to an alternative)
- Any P/Invoke or native interop calls

## 6. Review NuGet Package Compatibility

Check that all NuGet dependencies support the target framework. Open the `.csproj` file and verify each `<PackageReference>` resolves without issues. You can also run:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any outdated or vulnerable packages as appropriate.

## 7. Publish the Application

Once validation is complete, publish the application for the desired target:

**Framework-dependent (requires .NET runtime on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed.

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm the expected binaries and assets are present. Run the published output directly to perform a final smoke test:

```bash
./publish/AdoCore
```

or on Windows:

```powershell
.\publish\AdoCore.exe
```