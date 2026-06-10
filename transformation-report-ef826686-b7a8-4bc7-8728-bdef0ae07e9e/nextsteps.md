# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Check all `<PackageReference>` entries in `AdoCore.csproj` and any other projects in the solution. Ensure that packages targeting `.NET Framework` have been replaced with their `.NET`-compatible equivalents. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any test failures before proceeding. Pay particular attention to tests covering data access, I/O, or platform-specific functionality, as these areas are most commonly affected by cross-platform migrations.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs behave differently or are unavailable on non-Windows platforms. Use the .NET Compatibility Analyzer or review the code manually for usage of:

- `System.Windows.Forms` or `System.Drawing` (requires additional packages on non-Windows)
- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop
- `System.Security.Permissions` attributes

Run the following to surface platform compatibility warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

## 6. Test on Target Platform

If the goal is cross-platform support, run and test the application on each intended operating system (e.g., Linux, macOS) to surface any runtime-only platform issues:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime <RID> --self-contained true
```

Replace `<RID>` with the appropriate Runtime Identifier, such as:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

The published output will be located in the `bin/Release/<TargetFramework>/<RID>/publish/` directory.