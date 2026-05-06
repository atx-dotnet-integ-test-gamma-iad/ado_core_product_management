# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the root of the solution to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that were not caught as hard errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check for Removed or Changed APIs
Even without build errors, some APIs behave differently on cross-platform .NET. Review any code that uses:

- `System.Windows.Forms` or `System.Drawing` (requires explicit NuGet packages on non-Windows)
- `System.Configuration.ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)
- `Microsoft.Win32` registry APIs (Windows-only)
- `AppDomain`, `BinaryFormatter`, or `Remoting` APIs (partially or fully obsolete)

Run the .NET Upgrade Assistant compatibility analyzer if a deeper audit is needed:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

### 5. Review NuGet Package Versions
Open the solution in Visual Studio or run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that were previously targeting .NET Framework and may now have newer cross-platform versions available.

### 6. Validate Platform-Specific Behavior
If the application is intended to run on non-Windows platforms, perform a test run on the target OS (Linux or macOS) to surface any runtime issues that would not appear during a Windows build.

```bash
dotnet run --configuration Release
```

### 7. Review Output Artifacts
Confirm the build output in the `bin/Release` folder contains the expected assemblies, runtime configuration files (`.runtimeconfig.json`), and that no unintended `.exe` or platform-specific artifacts are missing or misplaced.

### 8. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent (requires .NET runtime on target machine)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) as needed.