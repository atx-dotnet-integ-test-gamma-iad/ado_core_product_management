# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that could not be resolved.

### 3. Build the Solution
Perform a full build to confirm there are no errors in the restored state:

```bash
dotnet build --configuration Release
```

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral differences introduced by the migration.

### 5. Check for Platform-Specific API Usage
Even without build errors, some APIs that compiled successfully may behave differently or throw at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any analyzer warnings related to platform-specific calls, such as those in `System.Drawing`, `Microsoft.Win32`, or P/Invoke declarations.

### 6. Review `App.config` / `Web.config` Usage
.NET does not use `App.config` or `Web.config` in the same way as .NET Framework. If the project previously relied on these files, migrate the relevant settings to `appsettings.json` and use `Microsoft.Extensions.Configuration` to read them.

### 7. Validate Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Windows, Linux, macOS) and verify that file paths, line endings, culture-sensitive operations, and any OS-level interactions behave as expected.

## Deployment

### 1. Publish a Self-Contained or Framework-Dependent Build
To produce a deployable output, use the `dotnet publish` command:

**Framework-dependent (smaller output, requires .NET runtime on the target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (includes the runtime, no dependency on installed .NET):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

### 2. Verify the Published Output
Navigate to the `./publish` directory and confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.