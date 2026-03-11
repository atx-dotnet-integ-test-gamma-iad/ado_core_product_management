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

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or platform compatibility.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests may indicate behavioral differences introduced by the migration.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any APIs that are Windows-only or otherwise platform-restricted. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Look for `CA1416` warnings, which flag platform-specific API calls.

### 6. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that configuration has been moved to `appsettings.json` or another appropriate mechanism supported by the new hosting model.

### 7. Validate Runtime Behavior
Run the application locally and exercise the primary workflows to confirm that runtime behavior matches the legacy project. Pay particular attention to:

- File I/O paths (path separator differences between Windows and Linux/macOS)
- Registry access (not available on non-Windows platforms)
- COM interop or P/Invoke calls
- Windows-specific authentication mechanisms

## Deployment

### 1. Publish the Application
Use the `dotnet publish` command to produce deployment artifacts:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

### 2. Verify the Published Output
Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present.

### 3. Test the Published Output
Run the published output directly on the target platform to confirm it operates correctly outside of the development environment:

```bash
./publish/YourApp
```

or on Windows:

```bash
./publish/YourApp.exe
```