# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is intact:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific APIs that may not behave as expected on Linux or macOS:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Drawing` references
- Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` support the target framework. You can inspect compatibility on [nuget.org](https://www.nuget.org) or by reviewing the output of:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

If the application uses file paths, environment variables, or line endings, verify these are handled in a platform-neutral way (e.g., using `Path.Combine` instead of hardcoded separators).

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish/linux-x64
```

Review the contents of the output directory to confirm all required assets are present before deploying.