# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or platform-specific code paths that could cause issues at runtime.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific Code

Search the codebase for APIs that are known to be Windows-only, such as:

- `System.Windows.Forms`
- `Microsoft.Win32.Registry`
- `System.Drawing` (GDI+ based)
- P/Invoke calls targeting Windows DLLs (e.g., `kernel32.dll`, `user32.dll`)

If any are found, either replace them with cross-platform alternatives or annotate them with the `[SupportedOSPlatform("windows")]` attribute and add appropriate runtime guards.

## 5. Validate NuGet Package Compatibility

Check that all NuGet dependencies support the target framework. Run the following and inspect the output for any compatibility warnings:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions compatible with your target framework.

## 6. Test on Target Platforms

Run the application on each platform you intend to support (e.g., Linux, macOS, Windows) to surface any runtime issues that would not appear during a Windows-only build:

```bash
dotnet run --configuration Release
```

Pay particular attention to:

- File path separators (`/` vs `\`)
- Case-sensitive file systems (Linux)
- Environment variable differences across operating systems

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish/linux-x64
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish/win-x64
```

Review the contents of the output directory to confirm all required files are present before deploying.