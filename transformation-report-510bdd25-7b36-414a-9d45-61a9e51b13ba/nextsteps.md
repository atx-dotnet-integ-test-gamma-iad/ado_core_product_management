# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, such as platform-specific API usage.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate runtime differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the code manually for any APIs that are Windows-specific. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` (requires additional packages or is unsupported on non-Windows)
- `Microsoft.Win32` registry access
- COM interop or P/Invoke calls
- `System.Web` (not available in cross-platform .NET; consider migrating to `Microsoft.AspNetCore`)

Run the following to surface platform compatibility warnings:

```bash
dotnet build --configuration Release /p:EnableNETAnalyzers=true
```

## 5. Review NuGet Package Compatibility

Check that all NuGet dependencies support the target framework. Open the `.csproj` file and verify each `<PackageReference>` resolves without issues. You can also run:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any packages that do not support the new TFM or that have known vulnerabilities.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime(s). For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true -o ./publish/linux-x64
dotnet publish --configuration Release --runtime win-x64 --self-contained true -o ./publish/win-x64
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release -o ./publish
```

Review the output directory to confirm all required files are present before distributing or deploying.