# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause outright build failures.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, threading, or reflection behavior).

### 4. Review NuGet Package Compatibility
Check that all NuGet packages referenced in each `.csproj` are compatible with the target framework. You can inspect this with:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Replace any packages that are outdated, vulnerable, or that have known incompatibilities with modern .NET.

### 5. Check for Removed or Changed APIs
Run the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to surface any API usage that may compile but behave differently at runtime:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

Pay particular attention to areas such as:
- `System.Web` usage (not available in modern .NET)
- `BinaryFormatter` (disabled by default in .NET 5+)
- `AppDomain` APIs with limited support
- Windows-only APIs if cross-platform execution is required

### 6. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch platform-specific runtime issues that would not appear at compile time.

### 7. Publish the Application
Once validation is complete, produce a release build artifact using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be pre-installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime <runtime-identifier> --output ./publish
```

Replace `<runtime-identifier>` with the appropriate value for your target environment, such as `win-x64`, `linux-x64`, or `osx-x64`.

Review the contents of the `./publish` folder to confirm all expected files are present before deploying to the target environment.